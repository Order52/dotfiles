// SPDX-License-Identifier: GPL-2.0
/*
 * acer_rear_wmi - rear light, power mode and a few read-backs of the Acer Predator Helios 16 (PH16-71)
 *
 * Binds the Acer gaming WMI GUID (the one acer-wmi calls WMID_GUID4) and exposes /dev/acer-rear.
 * Write one text command, read the reply back on the same file descriptor. Only the methods below are
 * reachable, and every input is validated - this is NOT a generic "call any WMI method" interface.
 *
 *   get_rear              method 21, input 2  -> current rear light state (16-byte layout of set_rear)
 *   get_slot              method 21, input 1  -> stored static colour slot
 *   set_rear <32 hex>     method 20           -> mode speed brightness 0 dir R G B 03 02 0*6
 *   set_color <RRGGBB>    method 6            -> static colour of the rear lightbar (index 8, zone bit 1)
 *   get_mode              method 23, input 0x0B -> power mode (byte1 of the u64)
 *   get_modes             method 23, input 0x0A -> bitmask of supported power modes
 *   set_mode <0|1|4|5|6>  method 22, (mode << 8) | 0x0B
 *
 * Layout, method numbers and values come from PredatorSense on Windows, see docs/rear-rgb-wmi.md.
 */
#include <linux/acpi.h>
#include <linux/ctype.h>
#include <linux/fs.h>
#include <linux/hex.h>
#include <linux/kstrtox.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/uaccess.h>
#include <linux/wmi.h>

#define ACER_GUID4	"7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56"

#define M_SET_RGB	6	/* SetGamingRgbKb, u64 */
#define M_SET_KB	20	/* SetGamingKBBacklight, u8[16] */
#define M_GET_KB	21	/* GetGamingKBBacklight, u32 */
#define M_SET_MISC	22	/* SetGamingMiscSetting, u64 */
#define M_GET_MISC	23	/* GetGamingMiscSetting, u64 */

static struct wmi_device *acer_wdev;
static DEFINE_MUTEX(acer_lock);
static char acer_reply[192] = "err no command yet\n";

/* Run one whitelisted method; on success put "ok <result>" into acer_reply. */
static int acer_call(u32 method, const void *in, size_t in_len)
{
	struct acpi_buffer inb = { in_len, (void *)in };
	struct acpi_buffer outb = { ACPI_ALLOCATE_BUFFER, NULL };
	union acpi_object *obj;
	acpi_status st;

	if (!acer_wdev)
		return -ENODEV;

	st = wmidev_evaluate_method(acer_wdev, 0, method, &inb, &outb);
	if (ACPI_FAILURE(st)) {
		snprintf(acer_reply, sizeof(acer_reply), "err acpi status 0x%x\n", st);
		return -EIO;
	}

	obj = outb.pointer;
	if (!obj)
		snprintf(acer_reply, sizeof(acer_reply), "ok\n");
	else if (obj->type == ACPI_TYPE_INTEGER)
		snprintf(acer_reply, sizeof(acer_reply), "ok int 0x%llx\n", (unsigned long long)obj->integer.value);
	else if (obj->type == ACPI_TYPE_BUFFER)
		snprintf(acer_reply, sizeof(acer_reply), "ok buf %*phN\n",
			 (int)min_t(u32, obj->buffer.length, 40), obj->buffer.pointer);
	else
		snprintf(acer_reply, sizeof(acer_reply), "ok type %d\n", obj->type);
	kfree(obj);
	return 0;
}

static int acer_call_u32(u32 method, u32 v)
{
	__le32 le = cpu_to_le32(v);

	return acer_call(method, &le, sizeof(le));
}

static int acer_call_u64(u32 method, u64 v)
{
	__le64 le = cpu_to_le64(v);

	return acer_call(method, &le, sizeof(le));
}

static int acer_set_rear(const char *hex)
{
	u8 b[16];

	if (strlen(hex) != 32 || hex2bin(b, hex, 16))
		return -EINVAL;
	/* modes: 0 static, 1 breathing, 2 neon, 3 wave, 7 twinkling; speed 1..5; brightness 0..100 */
	if (!(b[0] <= 3 || b[0] == 7) || b[1] < 1 || b[1] > 5 || b[2] > 100 || b[3] || b[4] > 1 ||
	    b[8] != 0x03 || b[9] != 0x02 || memchr_inv(&b[10], 0, 6))
		return -EINVAL;
	return acer_call(M_SET_KB, b, sizeof(b));
}

static int acer_set_color(const char *hex)
{
	u8 c[3];

	if (strlen(hex) != 6 || hex2bin(c, hex, 3))
		return -EINVAL;
	/* (zoneBit 1 << 40) | (rear lightbar index 8 << 32) | B << 24 | G << 16 | R << 8 */
	return acer_call_u64(M_SET_RGB, (1ULL << 40) | (8ULL << 32) | ((u64)c[2] << 24) | ((u64)c[1] << 16) | ((u64)c[0] << 8));
}

static int acer_set_mode(const char *arg)
{
	u8 m;

	if (kstrtou8(arg, 10, &m) || !(m == 0 || m == 1 || m == 4 || m == 5 || m == 6))
		return -EINVAL;
	return acer_call_u64(M_SET_MISC, ((u64)m << 8) | 0x0B);
}

static ssize_t acer_write(struct file *f, const char __user *ubuf, size_t len, loff_t *off)
{
	char buf[96], *cmd, *arg;
	int ret;

	if (!len || len >= sizeof(buf))
		return -EINVAL;
	if (copy_from_user(buf, ubuf, len))
		return -EFAULT;
	buf[len] = '\0';
	cmd = strim(buf);
	arg = strchr(cmd, ' ');
	if (arg) {
		*arg++ = '\0';
		arg = skip_spaces(arg);
	}

	mutex_lock(&acer_lock);
	if (!strcmp(cmd, "get_rear"))
		ret = acer_call_u32(M_GET_KB, 2);
	else if (!strcmp(cmd, "get_slot"))
		ret = acer_call_u32(M_GET_KB, 1);
	else if (!strcmp(cmd, "get_mode"))
		ret = acer_call_u64(M_GET_MISC, 0x0B);
	else if (!strcmp(cmd, "get_modes"))
		ret = acer_call_u64(M_GET_MISC, 0x0A);
	else if (!strcmp(cmd, "set_rear") && arg)
		ret = acer_set_rear(arg);
	else if (!strcmp(cmd, "set_color") && arg)
		ret = acer_set_color(arg);
	else if (!strcmp(cmd, "set_mode") && arg)
		ret = acer_set_mode(arg);
	else
		ret = -EINVAL;
	if (ret == -EINVAL)
		snprintf(acer_reply, sizeof(acer_reply), "err invalid command or argument\n");
	mutex_unlock(&acer_lock);

	return ret ? ret : len;
}

static ssize_t acer_read(struct file *f, char __user *ubuf, size_t len, loff_t *off)
{
	char tmp[sizeof(acer_reply)];

	mutex_lock(&acer_lock);
	strscpy(tmp, acer_reply, sizeof(tmp));
	mutex_unlock(&acer_lock);
	return simple_read_from_buffer(ubuf, len, off, tmp, strlen(tmp));
}

static const struct file_operations acer_fops = {
	.owner = THIS_MODULE,
	.write = acer_write,
	.read = acer_read,
	.llseek = noop_llseek,
};

static struct miscdevice acer_misc = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "acer-rear",
	.fops = &acer_fops,
	.mode = 0660,
};

static int acer_probe(struct wmi_device *wdev, const void *ctx)
{
	int ret;

	acer_wdev = wdev;
	ret = misc_register(&acer_misc);
	if (ret)
		acer_wdev = NULL;
	return ret;
}

static void acer_remove(struct wmi_device *wdev)
{
	misc_deregister(&acer_misc);
	mutex_lock(&acer_lock);
	acer_wdev = NULL;
	mutex_unlock(&acer_lock);
}

static const struct wmi_device_id acer_ids[] = {
	{ ACER_GUID4, NULL },
	{ }
};
MODULE_DEVICE_TABLE(wmi, acer_ids);

static struct wmi_driver acer_driver = {
	.driver = { .name = "acer-rear-wmi" },
	.id_table = acer_ids,
	.probe = acer_probe,
	.remove = acer_remove,
};
module_wmi_driver(acer_driver);

MODULE_DESCRIPTION("Acer Predator PH16-71 rear light / power mode over WMI (whitelisted methods only)");
MODULE_LICENSE("GPL");

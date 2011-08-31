#define KMSG_COMPONENT "example"
#define pr_fmt(fmt) KMSG_COMPONENT ": " fmt

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>

#define MAX_NUMBERS 4

static int number = 0;

static int numbers_count;
static int numbers[MAX_NUMBERS] = {0, 0, 0, 0};

MODULE_AUTHOR("Krzysztof Wilczynski <krzysztof.wilczynski@linux.com>");
MODULE_DESCRIPTION("Example Kernel module with two types of parameters");
MODULE_LICENSE("GPL");

module_param(number, int, 0444);
MODULE_PARM_DESC(number, "A numeric value");

module_param_array(numbers, int, &numbers_count, 0444);
MODULE_PARM_DESC(numbers, "A set of numeric values");

static int __init example_init(void)
{
	int i;

	pr_notice("module loaded.\n");
	pr_info("number = %d\n", number);
	
	if (numbers_count > 0) {
		pr_info("numbers (count = %d):\n", numbers_count);

		for (i = 0; i < numbers_count; i++) {
			pr_info("numbers[%d] = %d\n", i, numbers[i]);
		}
	}
	
	return 0;
}

static void __exit example_exit(void)
{
	pr_notice("module unloaded.\n");

	return;
}

module_init(example_init);
module_exit(example_exit);


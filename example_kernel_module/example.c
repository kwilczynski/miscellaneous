#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>

#define NAME_PREFIX "example: "
#define MAX_NUMBERS 4

static int number = 0;

static int numbers_count;
static int numbers[MAX_NUMBERS] = {0, 0, 0, 0};

MODULE_AUTHOR("Krzysztof Wilczynski <krzysztof.wilczynski@linux.com>");
MODULE_DESCRIPTION("Example Kernel module with two types of parameters");
MODULE_LICENSE("GPL");

module_param(number, int, 0400);
MODULE_PARM_DESC(number, "A numeric value");

module_param_array(numbers, int, &numbers_count, 0400);
MODULE_PARM_DESC(numbers, "A set of numeric values");

static int __init example_init(void)
{
	int i;

	printk(KERN_INFO NAME_PREFIX "module loaded.\n");
	printk(KERN_INFO NAME_PREFIX "number = %d\n", number);
	
	if (numbers_count > 0) {
		printk(KERN_INFO NAME_PREFIX "numbers (count = %d):\n",
			numbers_count);

		for (i = 0; i < numbers_count; i++) {
			printk(KERN_INFO NAME_PREFIX "numbers[%d] = %d\n",
			i, numbers[i]);
		}
	}
	
	return 0;
}

static void __exit example_exit(void)
{
	printk(KERN_INFO NAME_PREFIX "module unloaded.\n");

	return;
}

module_init(example_init);
module_exit(example_exit);


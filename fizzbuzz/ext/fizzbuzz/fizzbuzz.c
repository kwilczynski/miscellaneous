#include <ruby.h>

#define WANT_ARRAY(x) ((x) == (ARRAY))

typedef enum {
  ARRAY = 0,
  ENUMERATOR
} return_t;

static const char *words[] = {
  "Fizz", "Buzz",
  "FizzBuzz", NULL
};

static ID id_at_size;
static VALUE rb_cFizzBuzz = Qnil;

void Init_fizzbuzz(void);

static VALUE initialize(VALUE object, VALUE value);
static VALUE get_size(VALUE object);
static VALUE set_size(VALUE object, VALUE value);
static VALUE to_array(VALUE object);
static VALUE to_enumerator(VALUE object);

static VALUE calculate_fizzbuzz(VALUE object, return_t type);
static void validate_size(VALUE value);

static VALUE
initialize(VALUE object, VALUE value)
{
  validate_size(value);

  rb_ivar_set(object, id_at_size, value);
  return object;
}

static VALUE
get_size(VALUE object)
{
  return rb_ivar_get(object, id_at_size);
}

static VALUE
set_size(VALUE object, VALUE value)
{
  validate_size(value);

  rb_ivar_set(object, id_at_size, value);
  return Qnil;
}

static VALUE
to_enumerator(VALUE object)
{
  return calculate_fizzbuzz(object, ENUMERATOR);
}

static VALUE
to_array(VALUE object)
{
  return calculate_fizzbuzz(object, ARRAY);
}

static VALUE
calculate_fizzbuzz(VALUE object, return_t type)
{
  int i;
  int size = FIX2INT(rb_ivar_get(object, id_at_size));

  VALUE array;

  if (WANT_ARRAY(type)) {
    array = rb_ary_new();
  }
  else { 
    RETURN_ENUMERATOR(object, 0, 0);
  }

  for (i = 1; i <= size; i++) {
    if (i % 3 == 0) {
      WANT_ARRAY(type) ? rb_ary_push(array, rb_str_new2(words[0]))
                       : rb_yield(rb_str_new2(words[0]));
    }
    else if (i % 5 == 0) {
      WANT_ARRAY(type) ? rb_ary_push(array, rb_str_new2(words[1]))
                       : rb_yield(rb_str_new2(words[1]));
    }
    else if (i % 15 == 0) {
      WANT_ARRAY(type) ? rb_ary_push(array, rb_str_new2(words[2]))
                       : rb_yield(rb_str_new2(words[2]));
    }
    else {
      WANT_ARRAY(type) ? rb_ary_push(array, INT2FIX(i))
                       : rb_yield(INT2FIX(i));
    }
  }

  return WANT_ARRAY(type) ? array : object;
}

void
validate_size(VALUE value)
{
  if (!FIXNUM_P(value))
    rb_raise(rb_eTypeError, "invalid value for size");

  if (FIX2INT(value) < 1)
    rb_raise(rb_eArgError, "incorrect value for size");
}
  
void
Init_fizzbuzz(void)
{
  id_at_size = rb_intern("@size");

  rb_cFizzBuzz = rb_define_class("FizzBuzz", rb_cObject);

  rb_include_module(rb_cFizzBuzz, rb_mEnumerable);

  rb_define_method(rb_cFizzBuzz, "initialize", initialize, 1);

  rb_define_method(rb_cFizzBuzz, "size", get_size, 0);
  rb_define_method(rb_cFizzBuzz, "size=", set_size, 1);

  rb_define_method(rb_cFizzBuzz, "each", to_enumerator, 0);
  rb_define_method(rb_cFizzBuzz, "to_a", to_array, 0);
}

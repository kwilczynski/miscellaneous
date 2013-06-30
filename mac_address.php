<?php
  class Mac
  {
    static public function string_to_integer($string)
    {
      $result = 0;
      $string = Mac::strip_delimiter($string);

      # This implementation of unpack() is rather odd ...
      $values = unpack("A2_0/A2_1/A2_2/A2_3/A2_4/A2_5", $string);
    
      foreach ($values as $value)
      {
        $result = $result * pow(2, 8) + hexdec($value);
      }
    
      return $result;
    }

    static public function integer_to_string(
      $integer, $delimiter = ':', $upper_case = true
    )
    {
      $result  = array();
      $integer = (int) $integer;

      for ($i = 0; $i < 6; $i += 1)
      {
        $reminder = $integer % pow(2, 8);
        array_push($result, sprintf("%02x", $reminder));
        $integer = $integer / pow(2, 8);
      }
    
      $result = join($delimiter, array_reverse($result));
    
      return $upper_case ? strtoupper($result) : $result;
    }
  
    static private function strip_delimiter($string)
    {
      $search = array(':', '-', '.');
      return str_replace($search, '', trim($string));
    }
  }
?>
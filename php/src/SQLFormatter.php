<?php

class SQLFormatter {
  private static $sep = '~::~';

  public function format($sql, $numSpaces) {
    $tab = str_repeat(' ', $numSpaces);
    $splitByQuotes = explode(self::$sep, preg_replace('/\s+/', ' ', preg_replace("/'/", self::$sep . "'", $sql)));
    $input = array(
      'str' => '',
      'shiftArr' => $this->createShiftArr($tab),
      'tab' => $tab,
      'parensLevel' => 0,
      'deep' => 0
    );

    $inArr = $this->genArray($splitByQuotes, $tab);
    $outArr = array();
    $acc = $input;
    foreach($inArr as $i => $originalEl) {
      $parensLevel = $this->subqueryLevel($originalEl, $acc['parensLevel']);
      $el = preg_match('/SELECT|SET/', $originalEl) ? preg_replace('/,\s+/', ",\n" . $acc['tab'] . $acc['tab'], $originalEl) : $originalEl;
      $out = $this->updateOutput($el, $parensLevel, $acc);

      $outArr[$i] = $el;
      $acc['str'] = $out[0];
      $acc['parensLevel'] = $parensLevel;
      $acc['deep'] = $out[1];
    }

    return trim(preg_replace('/\s+\n/', "\n", preg_replace('/\n+/', "\n", $acc['str'])));
  }

  private function updateOutput($el, $parensLevel, $acc) {
    if (preg_match('/\(\s*SELECT/', $el)) {
      return array(($acc['str'] . $acc['shiftArr'][$acc['deep'] + 1] . $el), $acc['deep'] + 1);
    } else {
      return array(
        (preg_match("/'/", $el) ? ($acc['str'] . $el) : ($acc['str'] . $acc['shiftArr'][$acc['deep']] . $el)),
        ($parensLevel < 1 && $acc['deep'] !== 0 ? $acc['deep'] - 1 : $acc['deep'])
      );
    }
  }

  private function createShiftArr($tab) {
    $arr = array();
    for ($i = 0; $i < 100; $i++) {
      array_push($arr, "\n" . str_repeat($tab, $i));
    }
    return $arr;
  }

  private function genArray($splitByQuotes, $tab) {
    $arr = array();
    foreach($splitByQuotes as $i => $a) {
      foreach($this->splitIfEven($i, $splitByQuotes[$i], $tab) as $el) {
        $arr[] = $el;
      }
    }
    return $arr;
  }

  private function subqueryLevel($str, $level) {
    return $level - (strlen(preg_replace('/\(/', '', $str)) - strlen(preg_replace('/\)/', '', $str)));
  }

  private function allReplacements($tab) {
    return array(
      '/ AND /i'                              => self::$sep . $tab . 'AND ',
      '/ BETWEEN /i'                          => self::$sep . $tab . 'BETWEEN ',
      '/ CASE /i'                             => self::$sep . $tab . 'CASE ',
      '/ ELSE /i'                             => self::$sep . $tab . 'ELSE ',
      '/ END /i'                              => self::$sep . $tab . 'END ',
      '/ FROM /i'                             => self::$sep . 'FROM ',
      '/ GROUP\s+BY /i'                       => self::$sep . 'GROUP BY ',
      '/ HAVING /i'                           => self::$sep . 'HAVING ',
      '/ IN /i'                               => ' IN ',
      '/ JOIN /i'                             => self::$sep . 'JOIN ',
      '/ CROSS(~::~)+JOIN /i'                 => self::$sep . 'CROSS JOIN ',
      '/ INNER(~::~)+JOIN /i'                 => self::$sep . 'INNER JOIN ',
      '/ LEFT(~::~)+JOIN /i'                  => self::$sep . 'LEFT JOIN ',
      '/ RIGHT(~::~)+JOIN /i'                 => self::$sep . 'RIGHT JOIN ',
      '/ ON /i'                               => self::$sep . $tab . 'ON ',
      '/ OR /i'                               => self::$sep . $tab . 'OR ',
      '/ ORDER\s+BY /i'                       => self::$sep . 'ORDER BY ',
      '/ OVER /i'                             => self::$sep . $tab . 'OVER ',
      '/\(\s*SELECT /i'                       => self::$sep . '(SELECT ',
      '/\)\s*SELECT /i'                       => ')' . self::$sep . 'SELECT ',
      '/ THEN /i'                             => ' THEN' . self::$sep . $tab,
      '/ UNION /i'                            => self::$sep . 'UNION' . self::$sep,
      '/ USING /i'                            => self::$sep . 'USING ',
      '/ WHEN /i'                             => self::$sep . $tab . 'WHEN ',
      '/ WHERE /i'                            => self::$sep . 'WHERE ',
      '/ WITH /i'                             => self::$sep . 'WITH ',
      '/ SET /i'                              => self::$sep . 'SET ',
      '/ ALL /i'                              => ' ALL ',
      '/ AS /i'                               => ' AS ',
      '/ ASC /i'                              => ' ASC ',
      '/ DESC /i'                             => ' DESC ',
      '/ DISTINCT /i'                         => ' DISTINCT ',
      '/ EXISTS /i'                           => ' EXISTS ',
      '/ NOT /i'                              => ' NOT ',
      '/ NULL /i'                             => ' NULL ',
      '/ LIKE /i'                             => ' LIKE ',
      '/\s*SELECT /i'                         => 'SELECT ',
      '/\s*UPDATE /i'                         => 'UPDATE ',
      '/\s*DELETE /i'                         => 'DELETE ',
      '/(' . self::$sep . ')+/'               => self::$sep
    );
  }

  private function splitSql($str, $tab) {
    $str = preg_replace('/\s+/', ' ', $str);
    $regexes = $this->allReplacements($tab);
    foreach($regexes as $regex => $replacement) {
      $str = preg_replace($regex, $replacement, $str);
    }
    return explode(self::$sep, $str);
  }

  private function splitIfEven($i, $str, $tab) {
    return $i % 2 === 0 ? $this->splitSql($str, $tab) : array($str);
  }
}

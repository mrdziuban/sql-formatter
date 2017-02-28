"use strict";

exports.selectElement = function(el) {
  return function(e) {
    return function() {
      return el.select();
    };
  };
};

exports.setInnerHTML = function(html) {
  return function(el) {
    return function() {
      el.innerHTML = html;
    };
  };
};

exports.getValue = function(el) {
  return function() {
    return el.value;
  };
};

exports.setValue = function(el) {
  return function(val) {
    return function() {
      el.value = val;
    };
  };
};

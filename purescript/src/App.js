"use strict";

exports.setInnerHTML = function(html) {
  return function(el) {
    return function() {
      el.innerHTML = html;
    };
  };
};

exports.selectElement = function(el, e) { return function(e) { el.select(); }; };
exports.getValue = function(el) { return el.value; };
exports.setValue = function(el) { return function(val) { el.value = val; } };
exports.addEventListener = function(event, callback, el) {
  return function(callback) {
    return function(el) {
      el.addEventListener(event, callback);
    };
  };
};

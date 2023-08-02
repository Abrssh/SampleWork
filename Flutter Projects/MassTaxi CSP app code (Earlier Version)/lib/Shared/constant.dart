import 'package:flutter/material.dart';

const textInputDecoration = InputDecoration(
  // can comment the following
  // if you want white fill
  fillColor: Colors.blue,
  filled: false,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.blue,
      width: 2.0,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.pink,
      width: 2.0,
    ),
  ),
);

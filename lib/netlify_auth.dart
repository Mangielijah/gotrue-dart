library netlify_auth;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

part 'src/admin.dart';
part 'src/gotrue.dart';
part 'src/user.dart';
part 'src/interfaces.dart';
part 'src/utils.dart';

late SharedPreferences localStorage;

import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Photos prises dans l'app, manipulées en [XFile] pour fonctionner aussi
/// dans la version web (démo) : sur téléphone c'est un fichier, sur le web
/// une adresse (blob: ou http) lisible par le navigateur.
Widget imagePhoto(XFile photo, {BoxFit? fit, int? cacheWidth}) => kIsWeb
    ? Image.network(photo.path, fit: fit)
    : Image.file(io.File(photo.path), fit: fit, cacheWidth: cacheWidth);

ImageProvider providerPhoto(XFile photo) =>
    kIsWeb ? NetworkImage(photo.path) : FileImage(io.File(photo.path)) as ImageProvider;

Future<http.MultipartFile> multipartPhoto(String champ, XFile photo) async =>
    http.MultipartFile.fromBytes(champ, await photo.readAsBytes(),
        filename: photo.name.isNotEmpty ? photo.name : '$champ.jpg');

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagesPicker extends StatefulWidget{
  const UserImagesPicker({
    super.key,
    required this.onPickImage
  });

  final void Function(File pickedImage) onPickImage;

  @override
  State<UserImagesPicker> createState() {
    return _UserImagesPickerState();
  }
}

class _UserImagesPickerState extends State<UserImagesPicker> {

  File? _pickeImageFile;

  void _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 100);

    if(pickedImage == null) {
      return;
    }

    setState(() {
      _pickeImageFile = File(pickedImage.path);
    });

    widget.onPickImage(_pickeImageFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          // State変数として管理しているので、変更した瞬間にこいつだけリビルドが走る
          foregroundImage: _pickeImageFile != null ? FileImage(_pickeImageFile!) : null
        ),
        TextButton.icon(
          onPressed: _pickImage, 
          icon: const Icon(Icons.image),
          label: Text(
            'Add Image',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary
            ),
          )
        )
      ],
    );
  }
}
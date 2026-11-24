import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_run_tracker_app/models/run.dart';
import 'package:flutter_run_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class AddRunUI extends StatefulWidget {
  const AddRunUI({super.key});

  @override
  State<AddRunUI> createState() => _AddRunUIState();
}

class _AddRunUIState extends State<AddRunUI> {

  // ---------------------------------------------
  // ตัวแปรสำหรับเลือกรูปภาพ
  // ---------------------------------------------

  Uint8List? imageBytes;
  XFile? pickImage;

  // ---------------------------------------------
  // ตัวควบคุม TextField
  // ---------------------------------------------

  final TextEditingController runWhereCtrl =
      TextEditingController();

  final TextEditingController runPersonCtrl =
      TextEditingController();

  final TextEditingController runDistanceCtrl =
      TextEditingController();

  // ---------------------------------------------
  // สถานะการบันทึกข้อมูล
  // ---------------------------------------------

  bool isSaving = false;

  // ---------------------------------------------
  // Dispose Controller
  // ---------------------------------------------

  @override
  void dispose() {
    runWhereCtrl.dispose();
    runPersonCtrl.dispose();
    runDistanceCtrl.dispose();

    super.dispose();
  }

  // ---------------------------------------------
  // เลือกรูปภาพจากกล้องหรือ Gallery
  // ---------------------------------------------

  Future<void> selectImage(ImageSource source) async {
    try {
      final selectedImage = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );

      if (selectedImage != null) {
        final bytes = await selectedImage.readAsBytes();

        if (!mounted) return;

        setState(() {
          pickImage = selectedImage;
          imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'ไม่สามารถเลือกรูปภาพได้: $e',
        Colors.red,
      );
    }
  }

  // ---------------------------------------------
  // แสดงเมนูเลือกรูปภาพ
  // ---------------------------------------------

  void showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [

              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายรูปจากกล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  selectImage(ImageSource.camera);
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกรูปจาก Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  selectImage(ImageSource.gallery);
                },
              ),

              if (pickImage != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  title: const Text('ลบรูปภาพ'),
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      pickImage = null;
                      imageBytes = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------
  // แสดง SnackBar
  // ---------------------------------------------

  void showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------
  // บันทึกข้อมูลลง Supabase
  // ---------------------------------------------

  Future<void> saveRunData() async {

    // ตรวจสอบข้อมูลว่าง
    if (runWhereCtrl.text.trim().isEmpty ||
        runPersonCtrl.text.trim().isEmpty ||
        runDistanceCtrl.text.trim().isEmpty) {

      showMessage(
        'กรุณาป้อนข้อมูลให้ครบทุกช่อง',
        Colors.red,
      );

      return;
    }

    // ตรวจสอบระยะทาง
    final int? distance =
        int.tryParse(runDistanceCtrl.text.trim());

    if (distance == null || distance <= 0) {
      showMessage(
        'กรุณาป้อนระยะทางเป็นจำนวนเต็มที่มากกว่า 0',
        Colors.red,
      );

      return;
    }

    // ป้องกันการกดบันทึกซ้ำ
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {

      // 1. Upload รูปภาพไปยัง Supabase Bucket

      String imageUrl = '';

      if (pickImage != null) {
        imageUrl = await SupabaseService()
            .uploadFileToBucketRun(pickImage!);
      }

      // 2. สร้าง Object จาก Run Model

      Run run = Run(
        runWhere: runWhereCtrl.text.trim(),
        runPerson: runPersonCtrl.text.trim(),
        runDistance: distance,
        runImageUrl: imageUrl,
      );

      // 3. Insert ข้อมูลลง Table: run_tb

      await SupabaseService().insertDataToTableRun(run);

      if (!mounted) return;

      showMessage(
        'บันทึกข้อมูลเรียบร้อยแล้ว',
        Colors.green,
      );

      // 4. กลับไปหน้าก่อนหน้า

      Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      showMessage(
        'เกิดข้อผิดพลาด: $e',
        Colors.red,
      );

    } finally {

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------
  // Build UI
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // -------------------------------------------
      // AppBar
      // -------------------------------------------

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
          255,
          2,
          18,
          84,
        ),

        title: const Text(
          'Run Tracker (เพิ่ม)',
          style: TextStyle(
            color: Colors.white,
          ),
        ),

        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
      ),

      // -------------------------------------------
      // Body
      // -------------------------------------------

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 65,
            left: 40,
            right: 40,
            bottom: 50,
          ),

          child: Center(
            child: Column(
              children: [

                // ---------------------------------
                // ส่วนเลือกรูปภาพ
                // ---------------------------------

                InkWell(
                  onTap: showImagePickerOptions,

                  child: imageBytes == null

                      ? Icon(
                          Icons.add_a_photo,
                          size: MediaQuery.of(context)
                                  .size
                                  .width *
                              0.45,
                          color: Colors.grey,
                        )

                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),

                          child: Image.memory(
                            imageBytes!,
                            width: MediaQuery.of(context)
                                    .size
                                    .width *
                                0.45,
                            height: MediaQuery.of(context)
                                    .size
                                    .width *
                                0.45,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),

                const SizedBox(height: 45),

                // ---------------------------------
                // วิ่งที่ไหน
                // ---------------------------------

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วิ่งที่ไหน'),
                ),

                TextField(
                  controller: runWhereCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    hintText: 'เช่น สวนสาธารณะ, .....',
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------
                // วิ่งกับใคร
                // ---------------------------------

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วิ่งกับใคร'),
                ),

                TextField(
                  controller: runPersonCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    hintText: 'เช่น คุณเพื่อน, ครอบครัว, .....',
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------
                // ระยะทาง
                // ---------------------------------

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ระยะทาง (km)'),
                ),

                TextField(
                  controller: runDistanceCtrl,
                  keyboardType: TextInputType.number,

                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],

                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(6),
                    ),
                    hintText: 'เช่น 1, 5, .....',
                  ),
                ),

                const SizedBox(height: 30),

                // ---------------------------------
                // ปุ่มบันทึกข้อมูล
                // ---------------------------------

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : saveRunData,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                      255,
                      36,
                      145,
                      3,
                    ),

                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      55,
                    ),
                  ),

                  child: isSaving

                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )

                      : Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(
                            fontSize:
                                MediaQuery.of(context)
                                        .size
                                        .height *
                                    0.02,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------
                // ปุ่มยกเลิก
                // ---------------------------------

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                        },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,

                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      55,
                    ),
                  ),

                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context)
                                  .size
                                  .height *
                              0.02,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
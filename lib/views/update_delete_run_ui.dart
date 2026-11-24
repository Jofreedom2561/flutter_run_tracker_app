import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_run_tracker_app/models/run.dart';
import 'package:flutter_run_tracker_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class UpdateDeleteRunUI extends StatefulWidget {
  final Run? run;

  const UpdateDeleteRunUI({super.key, this.run});

  @override
  State<UpdateDeleteRunUI> createState() =>
      _UpdateDeleteRunUIState();
}

class _UpdateDeleteRunUIState extends State<UpdateDeleteRunUI> {

  // TextField Controllers
  final TextEditingController runWhereCtrl =
      TextEditingController();

  final TextEditingController runPersonCtrl =
      TextEditingController();

  final TextEditingController runDistanceCtrl =
      TextEditingController();

  // Image Variables
  Uint8List? imageBytes;
  XFile? pickImage;

  bool isLoading = false;

  // ---------------------------------
  // Select Image From Camera
  // ---------------------------------

  Future<void> selectImageFromCamera() async {

    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {

      final bytes = await image.readAsBytes();

      setState(() {
        pickImage = image;
        imageBytes = bytes;
      });

    }
  }

  // ---------------------------------
  // Init State
  // ---------------------------------

  @override
  void initState() {
    super.initState();

    if (widget.run != null) {

      runWhereCtrl.text =
          widget.run!.runWhere.toString();

      runPersonCtrl.text =
          widget.run!.runPerson.toString();

      runDistanceCtrl.text =
          widget.run!.runDistance.toString();

    }
  }

  // ---------------------------------
  // Dispose
  // ---------------------------------

  @override
  void dispose() {

    runWhereCtrl.dispose();
    runPersonCtrl.dispose();
    runDistanceCtrl.dispose();

    super.dispose();
  }

  // ---------------------------------
  // Update Run Data
  // ---------------------------------

  Future<void> updateRun() async {

    if (widget.run == null) return;

    if (runWhereCtrl.text.trim().isEmpty ||
        runPersonCtrl.text.trim().isEmpty ||
        runDistanceCtrl.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบ'),
        ),
      );

      return;
    }

    final int? distance =
        int.tryParse(runDistanceCtrl.text.trim());

    if (distance == null || distance <= 0) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกระยะทางให้ถูกต้อง'),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      // ใช้รูปเดิมก่อน
      String imageUrl =
          widget.run!.runImageUrl?.toString() ?? '';

      // ถ้ามีการเลือกรูปใหม่
      if (pickImage != null) {

        // Upload รูปใหม่ก่อน
        final String newImageUrl =
            await SupabaseService()
                .uploadFileToBucketRun(pickImage!);

        // ลบรูปเก่าหลังจาก Upload สำเร็จ
        if (imageUrl.isNotEmpty) {

          final String oldFileName =
              Uri.parse(imageUrl).pathSegments.last;

          await SupabaseService()
              .deleteFileFromBucketRun(oldFileName);
        }

        imageUrl = newImageUrl;
      }

      // สร้าง Object Run
      Run run = Run(

        runWhere: runWhereCtrl.text.trim(),

        runPerson: runPersonCtrl.text.trim(),

        runDistance: distance,

        runImageUrl: imageUrl,

      );

      // Update Database
      await SupabaseService().updateDataToTableRun(
        run,
        widget.run!.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

    }
  }

  // ---------------------------------
  // Delete Run Data
  // ---------------------------------

  Future<void> deleteRun() async {

    if (widget.run == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          title: const Text('ลบข้อมูล'),

          content: const Text(
            'คุณต้องการลบข้อมูล ใช่หรือไม่ ?',
          ),

          actions: [

            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('ยกเลิก'),
            ),

            // Confirm Delete
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ลบข้อมูล'),
            ),

          ],
        );

      },
    );

    // ถ้าไม่ยืนยัน ไม่ต้องลบ
    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    try {

      // Delete Image
      final String imageUrl =
          widget.run!.runImageUrl?.toString() ?? '';

      if (imageUrl.isNotEmpty) {

        final String fileName =
            Uri.parse(imageUrl).pathSegments.last;

        await SupabaseService()
            .deleteFileFromBucketRun(fileName);
      }

      // Delete Database
      await SupabaseService().deleteDataFromTableRun(
        widget.run!.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบข้อมูลเรียบร้อยแล้ว'),
        ),
      );

      // กลับหน้าก่อนหน้า
      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

    }
  }

  // ---------------------------------
  // Build UI
  // ---------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // AppBar
      appBar: AppBar(

        backgroundColor:
            const Color.fromARGB(255, 2, 18, 84),

        title: const Text(
          'Run Tracker (แก้ไข/ลบ)',
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

      // Body
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
                // Image
                // ---------------------------------

                InkWell(

                  onTap: selectImageFromCamera,

                  child: ClipRRect(

                    borderRadius:
                        BorderRadius.circular(12),

                    child: imageBytes != null

                        ? Image.memory(
                            imageBytes!,
                            width: MediaQuery.of(context)
                                    .size.width *
                                0.45,
                            height: MediaQuery.of(context)
                                    .size.width *
                                0.45,
                            fit: BoxFit.cover,
                          )

                        : widget.run?.runImageUrl != null &&
                                widget.run!.runImageUrl
                                    .toString()
                                    .isNotEmpty

                            ? Image.network(
                                widget.run!.runImageUrl
                                    .toString(),
                                width: MediaQuery.of(context)
                                        .size.width *
                                    0.45,
                                height: MediaQuery.of(context)
                                        .size.width *
                                    0.45,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.add_a_photo,
                                    size: 100,
                                    color: Colors.grey,
                                  );
                                },
                              )

                            : Icon(
                                Icons.add_a_photo,
                                size: MediaQuery.of(context)
                                        .size.width *
                                    0.45,
                                color: Colors.grey,
                              ),
                  ),
                ),

                const SizedBox(height: 45),

                // ---------------------------------
                // Run Where
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
                    hintText:
                        'เช่น สวนสาธารณะ, .....',
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------
                // Run Person
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
                    hintText:
                        'เช่น คุณเพื่อน, ครอบครัว, .....',
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------
                // Run Distance
                // ---------------------------------

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ระยะทาง (km)'),
                ),

                TextField(
                  controller: runDistanceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
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
                // Update Button
                // ---------------------------------

                ElevatedButton(

                  onPressed:
                      isLoading ? null : updateRun,

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(
                            255, 36, 145, 3),
                    foregroundColor: Colors.white,
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      55,
                    ),
                  ),

                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'บันทึกแก้ไขข้อมูล',
                          style: TextStyle(
                            fontSize:
                                MediaQuery.of(context)
                                        .size
                                        .height *
                                    0.02,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------
                // Delete Button
                // ---------------------------------

                ElevatedButton(

                  onPressed:
                      isLoading ? null : deleteRun,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      55,
                    ),
                  ),

                  child: const Text(
                    'ลบข้อมูล',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
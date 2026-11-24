// ignore_for_file: sort_child_properties_last

import 'package:material_ui/material_ui.dart';

import 'package:flutter_run_tracker_app/models/run.dart';
import 'package:flutter_run_tracker_app/services/supabase_service.dart';
import 'package:flutter_run_tracker_app/views/add_run_ui.dart';
import 'package:flutter_run_tracker_app/views/update_delete_run_ui.dart';

//------------------------------------//

class ShowAllRunUI extends StatefulWidget {
  const ShowAllRunUI({super.key});

  @override
  State<ShowAllRunUI> createState() => _ShowAllRunUIState();
}

//------------------------------------//

class _ShowAllRunUIState extends State<ShowAllRunUI> {

  // ตัวแปรเก็บข้อมูลการวิ่ง
  List<Run> runAllData = [];

  // ตัวแปรตรวจสอบ Loading
  bool isLoading = true;

  // ตัวแปรเก็บ Error
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    // เรียกฟังก์ชันดึงข้อมูล
    getRunData();
  }

  //------------------------------------//

  // ฟังก์ชันดึงข้อมูลจาก Supabase
  Future<void> getRunData() async {

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {

      final data = await SupabaseService().getAllDataFromTableRun();

      if (!mounted) return;

      setState(() {
        runAllData = data;
        isLoading = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });

    }
  }

  //------------------------------------//

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // AppBar
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 2, 18, 84),

        title: const Text(
          'Run Tracker',
          style: TextStyle(
            color: Colors.white,
          ),
        ),

        centerTitle: true,
      ),

      // FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          // เปิดหน้า AddRunUI
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRunUI(),
            ),
          );

          // โหลดข้อมูลใหม่
          if (!mounted) return;

          getRunData();
        },

        backgroundColor: const Color.fromARGB(255, 2, 18, 84),

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,

      //------------------------------------//

      // Body
      body: Center(
        child: Column(
          children: [

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),

            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: MediaQuery.of(context).size.width * 0.35,
              height: MediaQuery.of(context).size.width * 0.35,
              fit: BoxFit.contain,
            ),

            // App Name
            Text(
              'วิ่งกันเถอะ',
              style: TextStyle(
                fontSize:
                    MediaQuery.of(context).size.height * 0.025,
                fontWeight: FontWeight.bold,
              ),
            ),

            //------------------------------------//

            // แสดงข้อมูลตามสถานะ
            Expanded(
              child: isLoading

                  // Loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )

                  // Error
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.red,
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                'ไม่สามารถโหลดข้อมูลได้',
                              ),

                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                              ),

                              ElevatedButton(
                                onPressed: getRunData,
                                child: const Text('ลองอีกครั้ง'),
                              ),
                            ],
                          ),
                        )

                      // ไม่มีข้อมูล
                      : runAllData.isEmpty
                          ? const Center(
                              child: Text(
                                'ยังไม่มีข้อมูลการวิ่ง',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            )

                          // แสดงรายการข้อมูล
                          : ListView.separated(

                              itemCount: runAllData.length,

                              separatorBuilder: (context, index) {
                                return const Divider();
                              },

                              itemBuilder: (context, index) {

                                final run = runAllData[index];

                                final imageUrl =
                                    run.runImageUrl ?? '';

                                return ListTile(

                                  // กดเพื่อแก้ไขหรือลบข้อมูล
                                  onTap: () async {

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UpdateDeleteRunUI(
                                          run: run,
                                        ),
                                      ),
                                    );

                                    if (!mounted) return;

                                    getRunData();
                                  },

                                  // รูปภาพ
                                  leading: imageUrl.isEmpty

                                      ? Image.asset(
                                          'assets/images/logo.png',
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
                                          fit: BoxFit.cover,
                                        )

                                      : Image.network(
                                          imageUrl,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
                                          fit: BoxFit.cover,

                                          // กรณีโหลดรูปไม่สำเร็จ
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                            );
                                          },
                                        ),

                                  // สถานที่วิ่ง
                                  title: Text(
                                    run.runWhere ?? '-',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.015,
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
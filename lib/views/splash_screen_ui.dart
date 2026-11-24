import 'package:material_ui/material_ui.dart';
import 'package:flutter_run_tracker_app/views/show_all_run_ui.dart';

//------------------------------------//

class SplashScreenUI extends StatefulWidget {
  const SplashScreenUI({super.key});

  @override
  State<SplashScreenUI> createState() => _SplashScreenUIState();
}

//------------------------------------//

class _SplashScreenUIState extends State<SplashScreenUI> {

  @override
  void initState() {
    super.initState();

    // Delay หน้าจอ 3 วินาที แล้วเปิด ShowAllRunUI()
    Future.delayed(
      const Duration(seconds: 3),
      () {
        // ตรวจสอบว่า Widget ยังทำงานอยู่หรือไม่
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ShowAllRunUI(),
          ),
        );
      },
    );
  }

  //------------------------------------//

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 18, 84),

      body: Stack(
        children: [

          // ชั้นแรก รูปโลโก้ ชื่อแอป และ Progress
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.width * 0.5,
                  fit: BoxFit.contain,
                ),

                // App Name
                Text(
                  'RUN TRACKER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:
                        MediaQuery.of(context).size.height * 0.035,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // Loading
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
              ],
            ),
          ),

          // ชั้นที่สอง ข้อความด้านล่าง
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                Text(
                  '© 2026 RUN TRACKER',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),

                Text(
                  'Created by NinniN SAU TEAM',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(
                  height: 50.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
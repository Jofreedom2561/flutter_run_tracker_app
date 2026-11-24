import 'package:material_ui/material_ui.dart';
import 'package:flutter_run_tracker_app/views/splash_screen_ui.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  

//------------------------------------------------------
void main() async {
  //----------ตั้งค่าการเชื่อมต่อกับ Supabase----------
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url:'https://ljnsmhljshhddonkrhvz.supabase.co', 
    publishableKey: 'sb_publishable_SvUJxBToTRdOHdonGLr0yw_9F-C-BtD',
  );//ได้แล้วนิ หรือยังไม่ได้
  //----------------------------------------
  
  runApp(
    FlutterRunTrackerApp(),
  );
}

//-------------------------------------//
class FlutterRunTrackerApp extends StatelessWidget {
  const FlutterRunTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: const SplashScreenUI(),

      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
    );
  }
}
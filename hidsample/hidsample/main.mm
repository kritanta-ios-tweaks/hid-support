//
//#if defined __cplusplus
//aasadf;
//#endif


//extern "C" {
#include "hid-support.h"
//}
#include <string>
#include <iostream>

#define VERIFY(x) \
  ret = (x); \
  if(0 != ret){ \
    std::cerr << "Error !" << #x << "ret=" << ret <<std::endl; \
  }

void testInjectText(int argc, char **argv);

void testHomeButtonPress(int argc, char **argv);

void testMouseMove(int argc, char **pString);

void testGetScreenDimension(int argc, char **pString);

void testKeyDownUp(int argc, char **pString);

void usage(){
    std::cout << "1: hid_inject_text [demotext] " << std::endl
              << "2: hid_inject_button_down/up(HOME) " << std::endl
              << "3: hid_inject_mouse_abs_move x, y[auto]" <<std::endl
              << "4: hid_get_screen_dimension " << std::endl
              << "5: hid_inject_key_down/up" << std::endl
              << std::endl;
}

int main(int argc, char **argv, char **envp) {
    //std::cout << "argc=" << argc << ",argv[0]=" << argv[0] << std::endl;
    if(argc <= 1){
        usage();
        return -1;
    }

    int choice = atoi(argv[1]);
    switch(choice){
        case 1:
            testInjectText(argc, argv);
            break;
        case 2:
            testHomeButtonPress(argc, argv);
            break;
        case 3:
            testMouseMove(argc, argv);
            break;
        case 4:
            testGetScreenDimension(argc, argv);
            break;
        case 5:
            testKeyDownUp(argc, argv);
            break;
        default:
            usage();
            break;
    }

	return 0;
}

void testKeyDownUp(int argc, char **pString) {
    std::cout << "before " << __FUNCTION__ << std::endl;
    int ret = 0;

    for (int i = 'a'; i < 'z'; ++i) {
        VERIFY(hid_inject_key_down(i, 0));
        VERIFY(hid_inject_key_up(i));
    }
    for (int i = 'A'; i < 'Z'; ++i) {
        VERIFY(hid_inject_key_down(i, 0));
        VERIFY(hid_inject_key_up(i));
    }
    for (int i = '0'; i < '9'; ++i) {
        VERIFY(hid_inject_key_down(i, 0));
        VERIFY(hid_inject_key_up(i));
    }

}

void testGetScreenDimension(int argc, char **pString) {
    std::cout << "before " << __FUNCTION__ << std::endl;
    int ret = 0;

    int width = -1, height = -1;
    VERIFY(hid_get_screen_dimension(&width, &height));
    std::cout << "width=" << width << ", height=" << height <<std::endl;
}

void testInjectText(int argc, char **argv) {
    std::cout << "before " << __FUNCTION__ << std::endl;
    int ret = 0;
    const char* text = "demo text";
    if(argc > 2){
        text = argv[2];
    }
    VERIFY(hid_inject_text(text));
}

void testHomeButtonPress(int argc, char **argv) {
    std::cout << "before " << __FUNCTION__ << std::endl;
    int ret = 0;

    VERIFY(hid_inject_button_down(HWButtonHome))
    VERIFY(hid_inject_button_up(HWButtonHome))
}

void testMouseMove(int argc, char **pString) {
    std::cout << "before " << __FUNCTION__ << std::endl;
    int ret = 0;

    //hid_inject_mouse_abs_move(mouse, x*scale, y*scale);
    VERIFY(hid_inject_mouse_abs_move(1, 200, 50))
    VERIFY(hid_inject_mouse_abs_move(0, 200, 50))
}


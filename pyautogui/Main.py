import pyautogui
import time
# import emoji

time.sleep(10)

# with open(file="temp.txt", mode="r") as myfile:
    # for _ in myfile.readlines():
        # print(_, end="")

counter = 0
# heart = emoji.emojize(':red_heart:')
while counter < 143:
    # print(heart)
    # pyautogui.typewrite("_-------")
    pyautogui.hotkey('ctrl', 'v')
    # pyautogui.typewrite(" ")
        # print(_)
    pyautogui.press("enter")
    # time.sleep(1)
    counter +=1
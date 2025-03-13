import pyautogui
import time
from tkinter import Tk, Button, Label, Text, messagebox
import sys

input_value = None

def get_input_from_tk_window(Title="Application Main Window", Message="Enter the value:"):
    root = Tk()
    root.title(Title)
    status_label = Label(root, text=Message)
    status_label.grid(row=0, column=0)
    root.geometry("400x100")
    def cancel_click():
        b1.destroy()
        b2.destroy()
        res.destroy()
        time.sleep(2)
        status_label.config(text="Exiting Application...")
        root.update()
        time.sleep(2)
        root.destroy()
        sys.exit()

    def submit_click():
        global input_value
        result = res.get(index1="1.0", index2="end-1c")
        res.destroy()
        b1.destroy()
        b2.destroy()
        if result == "":
            status_label.config(text="No Value Submitted")
            root.update()
            cancel_click()

        status_label.config(text="Submitted value: " + result)
        root.update()
        time.sleep(2)
        root.destroy()
        input_value = result
        
    res = Text(root, height=1, width=30)
    res.grid(row=0, column=1)
    b1 = Button(root, text="Submit", command=submit_click)
    b2 = Button(root, text="Cancel", command=cancel_click)
    b1.grid(column=0, row=2)
    b2.grid(column=1, row=2)

    root.mainloop()
    return input_value

def repeat_line(line, times, delay=0, key="enter"):
    for i in range(0, times):
        pyautogui.typewrite(line, interval=0.1)
        if key == "enter":
            pyautogui.press("enter")
        elif key == "shift+enter":
            pyautogui.hotkey("shift", "enter")
        time.sleep(delay)

def line_repeater(wait_before_start=10):
    line = get_input_from_tk_window(Title="Line Repeator", Message="Enter the line:")
    times = get_input_from_tk_window(Title="Line Repeator", Message="Enter the number of times to be repeated:")
    messagebox.showinfo("Line Repeator", "The line will be repeated " + times + f" times. Please switch to the target application and click on the text box to start the process in {wait_before_start} Seconds.")
    time.sleep(wait_before_start)
    repeat_line(line, int(times), delay=0.5, key="shift+enter")
    

if __name__ == "__main__":
    line_repeater(wait_before_start=7)
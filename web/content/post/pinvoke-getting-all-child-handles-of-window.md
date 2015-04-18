+++
title = "PINVOKE: Getting all child handles of window"
Description = ""
date = "2015-04-11T21:51:58+01:00"
menu = "post"
comments = "yes"
share = "yes"
categories = ["frameworks", "api"]
tags = ["windows", "debug"]
+++

If you don’t know I have a new job in Bulgaria. I went away form Web Development and now I’m working as Windows Developer. 
However, we had a client that exceed the number of window handles (more than 10 000) due to bad design of application.
While diagnosing his application, we needed to understand how many handles are created per window. 

Windows API provide the availability to get all child handles for specified handle. 
We should use `EnumChildWindows` function provided by `user32.dll`.

`EnumChildWindows` function enumerates the child windows that belong to the specified parent window by passing the handle to each child window, in turn,
to an application-defined callback function. `EnumChildWindows` continues until the last child window is enumerated or the callback function returns FALSE.

```
BOOL EnumChildWindows( 
         HWND hWndParent, 
         WNDENUMPROC lpEnumFunc, 
         LPARAM lParam 
);
```

- `hWndParent` - [in] Handle to the parent window whose child windows are to be enumerated.
- `lpEnumFunc` - [in] Pointer to an application-defined callback function.
- `lParam` - [in] Specifies an application-defined value to be passed to the callback function.

If a child window has created child windows of its own, `EnumChildWindows` enumerates those windows as well.

```
public class WindowHandleInfo
{
    private delegate bool EnumWindowProc(IntPtr hwnd, IntPtr lParam);
 
    [DllImport("user32")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumChildWindows(IntPtr window, EnumWindowProc callback, IntPtr lParam);
 
    private IntPtr _MainHandle;
 
    public WindowHandleInfo(IntPtr handle)
    {
        this._MainHandle = handle;
    }
 
    public List<IntPtr> GetAllChildHandles()
    {
        List<IntPtr> childHandles = new List<IntPtr>();
 
        GCHandle gcChildhandlesList = GCHandle.Alloc(childHandles);
        IntPtr pointerChildHandlesList = GCHandle.ToIntPtr(gcChildhandlesList);
 
        try
        {
            EnumWindowProc childProc = new EnumWindowProc(EnumWindow);
            EnumChildWindows(this._MainHandle, childProc, pointerChildHandlesList);
        }
        finally
        {
            gcChildhandlesList.Free();
        }
 
        return childHandles;
    }
 
    private bool EnumWindow(IntPtr hWnd, IntPtr lParam)
    {
        GCHandle gcChildhandlesList = GCHandle.FromIntPtr(lParam);
 
        if (gcChildhandlesList == null || gcChildhandlesList.Target == null)
        {
            return false;
        }
 
        List<IntPtr> childHandles = gcChildhandlesList.Target as List<IntPtr>;
        childHandles.Add(hWnd);
 
        return true;
    }
}
```


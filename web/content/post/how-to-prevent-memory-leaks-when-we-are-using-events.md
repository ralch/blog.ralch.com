+++
Description = ""
date = "2015-04-11T22:03:54+01:00"
menu = "post"
title = "How to prevent memory leaks when we are using events?"

+++

In the average development lifecycle is possible that event handlers that are attached to events of sources to not be destroyed in
coordination with the listener object that attached the handler to the source. This can lead to memory leaks. The developers to take
care about memory management not only when they use unmanaged resources but also when they attach new event handlers to specified event.

This problem was solved by Microsoft in Windows Presentation Foundation. They implmented 
[Weak Event Design Pattern](https://href.li/?http://msdn.microsoft.com/en-us/library/aa970850.aspx).


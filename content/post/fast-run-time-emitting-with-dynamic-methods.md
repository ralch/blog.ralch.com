+++
title = "Fast run time emitting with dynamic methods in .NET"
Description = ""
date = "2015-04-11T22:11:18+01:00"
menu = "post"
comments = "yes"
share = "yes"
tags = ["msnet", "csharp","reflection"]
categories = ["frameworks", "programming languages"]
+++

It was a long time since, I have blogged. Nevertheless, I did not loose the enthusiasm to share the interesting stuff that I face.
As component software developer, you should know how to access the properties of data source, when you create bound able controls (such as list control, combo box control or even grid control).
The performance has always been a issue due to the fact that the control should work with any type of data source (ex. DataSet, DataTable or Entity Objects). 
Such requirements cause usage of reflection to access all properties of unknown object type. Therefore, you should use the PropertyInfo or PropertyDescriptor  classes. 
The disadvantage of the reflection has been always the performance. However, there is good alterative that can give satisfactory speed and
unlimited power of the reflection. The Dynamic Methods provide lightweight code generation and execution of method at run-time via delegates.

[Dynamic methods](http://msdn.microsoft.com/en-us/library/sfk2s47t.aspx) expand the functionality of the types in the System.Reflection.Emit namespace in several ways:

- They have less overhead, because there is no need to generate dynamic assemblies, modules, and types to contain the methods.
- In long-running applications, they provide better resource utilization because the memory used by method bodies can be reclaimed when the method is no longer needed.
- Given sufficient security permissions, they provide the ability to associate code with an existing assembly or type, and that code can have the same visibility as internal types or private members.
- Given sufficient security permissions, they allow code to skip just-in-time (JIT) visibility checks and access the private and protected data of objects.

Before you define the method body, you should declare the delegate types that you should use to access the properties of the unknown type:

```
protected delegate void SetValueHandler(object component, object value);
protected delegate object GetValueHandler(object component);
```

Implementation of this methods requires Microsoft Intermediate Language (IL):

```
protected virtual GetValueHandler CreateGetValueHandler(PropertyInfo propertyInfo)
{
    MethodInfo getMethodInfo = propertyInfo.GetGetMethod();
    DynamicMethod getMethod = new DynamicMethod("GetValue", typeof(object), new Type[] { typeof(object) }, typeof(PropertyAccessor), true);
    ILGenerator ilGenerator = getMethod.GetILGenerator();

    ilGenerator.Emit(OpCodes.Ldarg_0);
    ilGenerator.Emit(OpCodes.Call, getMethodInfo);

    Type returnType = getMethodInfo.ReturnType;

    if (returnType.IsValueType)
    {
        ilGenerator.Emit(OpCodes.Box, returnType);
    }

    ilGenerator.Emit(OpCodes.Ret);

    return getMethod.CreateDelegate(typeof(GetValueHandler)) as GetValueHandler;

}   
```

Also, the body of the setter method should be created as it’s shown in the following code snippet:

```
protected virtual SetValueHandler CreateSetValueHandler(PropertyInfo propertyInfo)
{
    MethodInfo setMethodInfo = propertyInfo.GetSetMethod(false);
    DynamicMethod setPropertyValue = new DynamicMethod("SetValue", typeof(void), new Type[] { typeof(object), typeof(object) }, typeof(PropertyAccessor), true);
    ILGenerator ilGenerator = setPropertyValue.GetILGenerator();

    ilGenerator.Emit(OpCodes.Ldarg_0);
    ilGenerator.Emit(OpCodes.Ldarg_1);

    Type parameterType = setMethodInfo.GetParameters()[0].ParameterType;

    if (parameterType.IsValueType)
    {
        ilGenerator.Emit(OpCodes.Unbox_Any, parameterType);
    }

    ilGenerator.Emit(OpCodes.Call, setMethodInfo);
    ilGenerator.Emit(OpCodes.Ret);

    return setPropertyValue.CreateDelegate(typeof(SetValueHandler)) as SetValueHandler;
}
```

I have encapsulated the dynamic method accesses in the `PropertyAccessor` class, which declaration looks as follows:

```
public class PropertyAccessor
{
    protected delegate void SetValueHandler(object component, object value);
    protected delegate object GetValueHandler(object component);

    private SetValueHandler setValueHandler;
    private GetValueHandler getValueHandler;

    public PropertyAccessor(Type ownerType, string propertyName)
    {
        PropertyInfo propertyInfo = ownerType.GetProperty(propertyName);

        if (propertyInfo.CanRead)
        {
            this.getValueHandler = this.CreateGetValueHandler(propertyInfo);
        }

        if (propertyInfo.CanWrite)
        {
            this.setValueHandler = this.CreateSetValueHandler(propertyInfo);
        }
    }

    public object GetValue(object component)
    {
        if (this.getValueHandler == null)
        {
            throw new InvalidOperationException();
        }

        return this.getValueHandler(component);
    }

    public void SetValue(object component, object value)
    {
        if (this.setValueHandler == null)
        {
            throw new InvalidOperationException();
        }

        this.setValueHandler(component, value);
    }
}
```

I measured the performance among the three approaches against 1 000 000 times invocation of the `Employee` property:

{{< figure src="/media/dynamic_method_emit_diagram.png" alt="Dynamic methods performance diagram" >}}

Notice that the direct access approach followed by the Dynamic Methods implementation are the fastest.



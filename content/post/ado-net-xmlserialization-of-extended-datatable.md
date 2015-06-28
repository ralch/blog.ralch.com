+++
title = "ADO.NET XmlSerialization of extended DataTable"
Description = ""
date = "2015-04-11T21:10:37+01:00"
menu = "post"
comments = "yes"
share = "yes"
tags = ["msnet", "csharp", "soap", "adonet"]
categories = ["frameworks", "programming languages"]
+++

We are migrating communication protocol from .NET Remoting to WCF. 
Due to legacy fo this project, domain object is a DataTable that has some additional fields. 
In .NET Remoting serialization of that kind of object works perfectly, but in WCF these additional fields are not serialized.
Instead of binary serialization in .NET Remoting, XML serialization is used in WCF. 

Lets have a class that derives DataTable type:

```
public class WcfDataTable : DataTable
{
    private string _ServerName;
 
    public WcfDataTable()
        : base()
    { }
 
    public WcfDataTable(string tableName)
        : base(tableName)
    { }
 
    public string ServerName
    {
        get { return this._ServerName; }
        set { this._ServerName = value; }
    }
}
```

{{< figure src="/media/wcf_table_screen.jpg" alt="WCF DataTable" >}}

As you can see I’m creating dummy `WcfDataTable` object, which I’m cloning using xml serialization and deserialization. 
The cloned object is not identical with the original object, because this additional field is not initialized with the original value (it’s null). 
The existing xml serialization doesn’t catch the new field in the class.
To make possible this field for xml serialization we should override the existing xml serialization, but how to do it? 
The solution is really simple. You have to implement the interface `IXmlSerializable` with explicit override of all its methods.

```
public class WcfDataTable : DataTable, IXmlSerializable
{
    private string _ServerName;
 
    public WcfDataTable()
        : base()
    { }
 
    public WcfDataTable(string tableName)
        : base(tableName)
    { }
 
    public string ServerName
    {
        get { return this._ServerName; }
        set { this._ServerName = value; }
    }
 
    void IXmlSerializable.ReadXml(System.Xml.XmlReader reader)
    {
        base.ReadXmlSchema(reader);
 
        XmlSerializer xmlSerializer = new XmlSerializer(typeof(string));
        this._ServerName = xmlSerializer.Deserialize(reader) as string;
 
        base.ReadXml(reader);
    }
 
    void IXmlSerializable.WriteXml(System.Xml.XmlWriter writer)
    {
        base.WriteXmlSchema(writer);
 
        XmlSerializer xmlSerializer = new XmlSerializer(typeof(string));
        xmlSerializer.Serialize(writer, this._ServerName);
 
        base.WriteXml(writer, XmlWriteMode.DiffGram);
    }
}
```

To make this workaround we have to override WriteXml and ReadXml method explicitly. 
The methods ReadXmlSchema and WriteXmlSchema are used to read and write the schema of data table. 
Then we can write/read our new field and then to invoke basic logic for serialization or deserializtion. 

{{< figure src="/media/wcf_table_screen_done.jpg" alt="WCF DataTable" >}}




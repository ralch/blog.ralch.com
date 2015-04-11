+++
Description = ""
date = "2015-04-11T20:19:59+01:00"
menu = "post"
tags = ["C#", "csharp"]
title = "LINQ to SQL: Create generic method to load entity by primary key"

+++

# Scenario

We are implementing our data access layer based on LINQ TO SQL. In the specifications that were created by our software architect is required to have generic method that load from the data base any record into entity object by primary key.

```
public class LINQGateway<TEntity> where TEntity : class
{
    private IDbConnection _DbConnection;
    public LINQGateway(IDbConnection connection)
    {
        this._DbConnection = connection;
    }
    public TEntity GetEntityByPrimaryKey(object pkKey, params object[] pkKeys)
    {
        // TO DO
    }
}
```

# Problem

Every table has different primary key (count, name and data type of the primary key columns).

# Algorithm

1. Get tha mapping of the entity type
2. Use information for the mapping
  2.1 to get the name of the columns
  2.2 to get the name of the columns included in the primary key
3. Generate the T-SQL Query
4. Execute the Query via LINQ Framework to retrive the result as entity object

# Solutions

## Building T-SQL query

```
TEntity GetEntityByPrimaryKey(object pkKey, params object[] pkKeys)
{
    List<object> primaryKeys = new List<object>();
    primaryKeys.Add(pkKey);
    primaryKeys.AddRange(pkKeys);

    TEntity entity = null;
    Type entityType = typeof(TEntity);

    using (DataContext dataContext = new DataContext(this._DbConnection))
    {
        dataContext.Log = new DebuggerWriter();
        dataContext.ObjectTrackingEnabled = false;

        Table<TEntity> table = dataContext.GetTable<TEntity>();

        MetaType metaEntityType = dataContext.Mapping.GetMetaType(entityType);

        var primaryKeyColumns = from pkColumn in metaEntityType.DataMembers
                                where pkColumn.IsPrimaryKey
                                select pkColumn;

        var columns = from col in metaEntityType.DataMembers
                      where col.IsPersistent && !col.IsAssociation
                      orderby col.Ordinal
                      select "[t0].[" + col.MappedName + "]";

        string selectColumns = String.Join(", ", columns.ToArray());

        int pkColumnsCount = 0;

        if (primaryKeyColumns != null)
            pkColumnsCount = primaryKeyColumns.Count();

        if (pkColumnsCount == 0)
            throw new InvalidOperationException("Table doesn’t have primary key");

        if (pkColumnsCount != primaryKeys.Count)
            throw new InvalidOperationException("Primary key values doesn’t match primary key columns.");


        string tableName = metaEntityType.Table.TableName;

        if (tableName.Contains(‘.’))
        {
            string[] splittedTablename = metaEntityType.Table.TableName.Split(‘.’).Select(p => "[" + p + "]").ToArray();
            tableName = String.Join(".", splittedTablename);
        }

        StringBuilder builder = new StringBuilder("SELECT " + selectColumns + Environment.NewLine + "FROM " + tableName + " AS [t0]" + Environment.NewLine + "WHERE ");

        int index = 0;

        foreach (MetaDataMember pkColumn in primaryKeyColumns)
        {
            string columnName = pkColumn.Name;
            string paramID = index.ToString(CultureInfo.InvariantCulture);
            builder.Append("[t0].[" + columnName + "] = {" + paramID + "}");

            if (index + 1 != pkColumnsCount)
                builder.Append(" AND ");

            index++;
        }

        string query = builder.ToString();
        entity = dataContext.ExecuteQuery<TEntity>(query, primaryKeys.ToArray()).SingleOrDefault();
    }

    return entity;
}
```

## Dynamic LINQ expression

```
TEntity GetEntityByPrimaryKey(object pkKey, params object[] pkKeys)
{
    List<object> primaryKeys = new List<object>();
    primaryKeys.Add(pkKey);
    primaryKeys.AddRange(pkKeys);
 
    TEntity entity = null;
    Type entityType = typeof(TEntity);
 
    using (DataContext dataContext = new DataContext(this._DbConnection))
    {
        dataContext.Log = new DebuggerWriter();
        dataContext.ObjectTrackingEnabled = false;
 
        Table<TEntity> table = dataContext.GetTable<TEntity>();
 
        MetaType metaEntityType = dataContext.Mapping.GetMetaType(entityType);
 
        var primaryKeyColumns = from pkColumn in metaEntityType.DataMembers
                                where pkColumn.IsPrimaryKey
                                select pkColumn;
 
        int pkColumnsCount = 0;
 
        if (primaryKeyColumns != null)
            pkColumnsCount = primaryKeyColumns.Count();
 
        if (pkColumnsCount == 0)
            throw new InvalidOperationException("Table doesn’t have primary key");
 
        if (pkColumnsCount != primaryKeys.Count)
            throw new InvalidOperationException("Primary key value doesn’t match primary key columns.");
 
        ParameterExpression paramExpression = Expression.Parameter(entityType, "entity");
 
        BinaryExpression whereExpression = null;
 
        int index = 0;
 
        foreach (MetaDataMember pkColumn in primaryKeyColumns)
        {
            object value = primaryKeys[index];
            string columnName = pkColumn.Name;
 
            if (value != null && value.GetType() != pkColumn.Type)
            {
                Type paramType = value.GetType();
                string exceptionMsg = String.Format("The type ‘{0}’ of parameter ‘{1}’ is different than its column ‘{2}’ type ‘{3}’", paramType, value, columnName, pkColumn.Type);
                throw new InvalidOperationException(exceptionMsg);
            }
 
            BinaryExpression condition = Expression.Equal(Expression.Property(paramExpression, columnName), Expression.Constant(value));
 
            if (whereExpression != null)
                whereExpression = Expression.And(whereExpression, condition);
            else
                whereExpression = condition;
 
            index++;
        }
 
        Expression<Func<TEntity, bool>> predicate = Expression.Lambda<Func<TEntity, bool>>(whereExpression, new ParameterExpression[] { paramExpression });
        entity = table.SingleOrDefault(predicate);
    }
 
    return entity;
}
```

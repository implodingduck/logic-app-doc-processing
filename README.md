# logic-app-doc-processing

## SQL
```
CREATE USER [uai-ladocproc........] FROM EXTERNAL PROVIDER;
```

```
CREATE TABLE dbo.Documents (
    DocumentDate DATE NOT NULL, 
    Name NVARCHAR(100) NOT NULL,  
    Content NVARCHAR(MAX) NULL,
    Processor NVARCHAR(50) NOT NULL,        
    DocumentID INT IDENTITY(1,1) PRIMARY KEY 
);
```

```
EXEC sp_addrolemember 'db_owner', 'uai-ladocproc........';
```
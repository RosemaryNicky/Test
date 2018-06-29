DECLARE @begin DATETIME,@end DATETIME,@shanghutype INT, @beginshanghuarea BIGINT ,@endshanghuarea bigint
SELECT @begin='1753-01-01',@end='9999-12-31',@shanghutype=1,@beginshanghuarea=-1,@endshanghuarea=9223372036854775807
 
IF OBJECT_ID('tempdb.dbo.#tmp', 'U') IS NOT NULL
DROP TABLE #tmp;
CREATE TABLE #tmp
(
SysNo   BIGINT,
Source  INT,
ji  DECIMAL(20,6),
dai DECIMAL(20,6)
 
)
 
 
IF @shanghutype=1
BEGIN
 
    ;WITH    tmpj
              AS ( SELECT  
                            b.AdjustType ,
                            a.Source,
                            AdjustAmount = ISNULL(c.AdjustAmount, 0),
                            (CASE WHEN A.Source=1 THEN A.VendorSysNo ELSE A.DistributorSysNo END ) AS SysNo
                   FROM     [BBCAccount].[dbo].[Account] a WITH ( NOLOCK )
                            LEFT JOIN BBCFinance.dbo.AccountAdjustReceipt b WITH ( NOLOCK ) ON a.SysNo = b.AccountSysNo
                                                                  AND b.Status = 2
                            LEFT JOIN BBCFinance.dbo.AccountBalanceChange c WITH ( NOLOCK ) ON b.AccountSysNo = c.AccountSysNo
 
                            LEFT JOIN BBCAccount.dbo.Distributor distributor WITH(NOLOCK)  ON a.DistributorSysNo=distributor.SysNo
                            LEFT JOIN BBCAccount.dbo.Vendor vendor WITH(NOLOCK) ON A.VendorSysNo=vendor.SysNo
                WHERE (a.InDate BETWEEN  @begin  and @end ) 
                    AND a.SOURCE=@shanghutype 
                    AND ( a.VendorSysNo  BETWEEN @beginshanghuarea AND  @endshanghuarea)
    )
    INSERT INTO #tmp(SysNo,Source,ji,dai)
    SELECT  distinct
        (CASE WHEN a1.Source=1 THEN a1.VendorSysNo ELSE a1.DistributorSysNo END ) AS SysNo,
 
                a1.Source,
                ji = ( SELECT   SUM(bb.AdjustAmount)
                       FROM     tmpj bb
                       WHERE    (bb.SysNo = a1.VendorSysNo OR bb.SysNo=a1.DistributorSysNo)
                                AND bb.AdjustType = 1
                     ) ,
                dai = ( SELECT  SUM(bb.AdjustAmount)
                        FROM    tmpj bb
                        WHERE    (bb.SysNo = a1.VendorSysNo OR bb.SysNo=a1.DistributorSysNo)
                                AND bb.AdjustType = -1
                      )
     
        FROM    [BBCAccount].[dbo].[Account] a1 WITH ( NOLOCK )
        WHERE (a1.InDate BETWEEN  @begin  and @end ) 
                AND a1.SOURCE=@shanghutype 
                AND ( a1.VendorSysNo  BETWEEN @beginshanghuarea AND  @endshanghuarea)
                  
     
END
ELSE
BEGIN
    IF OBJECT_ID('tempdb.dbo.#tmp', 'U') IS NOT NULL
    DROP TABLE #tmp;
    ;WITH    tmpj
              AS ( SELECT  
                            b.AdjustType ,
                            a.Source,
                            AdjustAmount = ISNULL(c.AdjustAmount, 0),
                            (CASE WHEN A.Source=1 THEN A.VendorSysNo ELSE A.DistributorSysNo END ) AS SysNo
                   FROM     [BBCAccount].[dbo].[Account] a WITH ( NOLOCK )
                            LEFT JOIN BBCFinance.dbo.AccountAdjustReceipt b WITH ( NOLOCK ) ON a.SysNo = b.AccountSysNo
                                                                  AND b.Status = 2
                            LEFT JOIN BBCFinance.dbo.AccountBalanceChange c WITH ( NOLOCK ) ON b.AccountSysNo = c.AccountSysNo
 
                            LEFT JOIN BBCAccount.dbo.Distributor distributor WITH(NOLOCK)  ON a.DistributorSysNo=distributor.SysNo
                            LEFT JOIN BBCAccount.dbo.Vendor vendor WITH(NOLOCK) ON A.VendorSysNo=vendor.SysNo
                WHERE (a.InDate BETWEEN  @begin  and @end ) 
                    AND a.SOURCE=@shanghutype 
                    AND ( a.DistributorSysNo  BETWEEN @beginshanghuarea AND  @endshanghuarea)
    )
    INSERT INTO #tmp(SysNo,Source,ji,dai)
    SELECT  distinct
        (CASE WHEN a1.Source=1 THEN a1.VendorSysNo ELSE a1.DistributorSysNo END ) AS SysNo,
         
                a1.Source,
                ji = ( SELECT   SUM(bb.AdjustAmount)
                       FROM     tmpj bb
                       WHERE    (bb.SysNo = a1.VendorSysNo OR bb.SysNo=a1.DistributorSysNo)
                                AND bb.AdjustType = 1
                     ) ,
                dai = ( SELECT  SUM(bb.AdjustAmount)
                        FROM    tmpj bb
                        WHERE    (bb.SysNo = a1.VendorSysNo OR bb.SysNo=a1.DistributorSysNo)
                                AND bb.AdjustType = -1
                      )
 
        FROM    [BBCAccount].[dbo].[Account] a1 WITH ( NOLOCK )
        WHERE (a1.InDate BETWEEN  @begin  and @end ) 
                AND a1.SOURCE=@shanghutype 
                AND ( a1.DistributorSysNo  BETWEEN @beginshanghuarea AND  @endshanghuarea)
 
END
 
IF OBJECT_ID('tempdb.dbo.#tmp2', 'U') IS NOT NULL
    DROP TABLE #tmp2;
WITH    TMP
          AS ( SELECT   ROW_NUMBER() OVER ( PARTITION BY a.SysNo ORDER BY B.INDATE DESC ) AS RowNumber ,
                       -- a.SysNo ,
                        BU.Name ,
                        b.AdjustedBalance,
                        (CASE WHEN A.Source=1 THEN A.VendorSysNo ELSE A.DistributorSysNo END ) AS SysNo
               FROM     [BBCAccount].[dbo].[Account] a WITH ( NOLOCK )
                        LEFT JOIN BBCAccount.dbo.BusinessType BU WITH ( NOLOCK ) ON a.BizTypeCode = BU.Code
                                                              AND BU.ParentCode IS NULL
                                                              AND BU.Type = 0
                                                              AND BU.IsSystem = 1
                        LEFT JOIN BBCFinance.dbo.AccountBalanceChange b WITH ( NOLOCK ) ON a.SysNo = b.AccountSysNo
                        LEFT JOIN BBCFinance.dbo.AccountAdjustReceipt c ON b.AccountSysNo = c.AccountSysNo
                                                              AND b.BizID = c.ChangeNo
                        LEFT JOIN BBCAccount.dbo.Distributor distributor WITH(NOLOCK)  ON a.DistributorSysNo=distributor.SysNo
                        LEFT JOIN BBCAccount.dbo.Vendor vendor WITH(NOLOCK) ON A.VendorSysNo=vendor.SysNo
               WHERE    c.Status = 2
                        AND BU.Type = 0
                        AND BU.IsSystem = 1
                        AND BU.ParentCode IS NULL
                        AND BU.Type = 0
                        AND BU.IsSystem = 1
             ),
        TMP1
          AS ( SELECT   SysNo ,
                        Name ,
                        AdjustedBalance
               FROM     TMP
               WHERE    RowNumber = 1
             )
    SELECT  SysNo ,
            Name ,
            amount = SUM(AdjustedBalance)
    INTO    #tmp2
    FROM    TMP1
    GROUP BY Name ,
            SysNo;
 
 
 IF OBJECT_ID('tempdb.dbo.#tmp', 'U') IS NOT NULL
DROP TABLE #ty;
 
;WITH tt
AS
(
 
SELECT 
t1.SysNo,total=SUM(t2.amount)
FROM    #tmp t1
        LEFT JOIN #tmp2 t2 ON t1.SysNo = t2.SysNo
--WHERE 
-- t1.SysNo = 2272 
GROUP BY  t1.SysNo
 
 )
  
SELECT 
t1.SysNo,t1.Source,t1.ji,t1.dai,t2.Name,t2.amount,tt.total
INTO #ty
FROM    #tmp t1
        LEFT JOIN #tmp2 t2 ON t1.SysNo = t2.SysNo
LEFT JOIN tt
    ON t1.SysNo=tt.SysNo
--WHERE   t1.SysNo = 2272
 ORDER BY t1.SysNo;
 
 
 SELECT T.*, qmye=(ye+djye+kms+bzj+fxye) FROM ( SELECT SysNo,Source,ji AS jffse,dai AS dffse,
  ye=CASE WHEN Name='余额账户' THEN amount ELSE 0.00 END,
  djye=CASE WHEN Name='冻结余额账户' THEN amount ELSE 0.00 END,
  kms=CASE WHEN Name='跨贸税账户' THEN amount ELSE 0.00 END,
  bzj=CASE WHEN Name='保证金账户' THEN amount ELSE 0.00 END,
  fxye=CASE WHEN Name='供应商的分销余额' THEN amount ELSE 0.00 END
 FROM #ty)  AS T
 
--DECLARE @sql_col VARCHAR(8000)
--DECLARE @sql_str VARCHAR(8000)
--DECLARE @sql_ VARCHAR(MAX)
--SELECT @sql_col = ISNULL(@sql_col + ',','') + QUOTENAME(name) FROM #ty
--SET @sql_='
--select a.*,
--jie=(select top(1) ji  from #ty ty where ty.sysno=a.sysno),
--dai=(select top(1) dai  from #ty ty where ty.sysno=a.sysno)
--from
--(
--select *
--from(
--      select totAL,Name,SysNo  from #ty
--  )as tw
--pivot( max(totAL) for Name in('+@sql_col+') )piv
--) a
--'
--EXEC(@sql_)
 
--SELECT TOP(1) * FROM #ty 
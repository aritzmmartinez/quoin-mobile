/// An invented Trade Republic export for debug builds, dated around [now]. It
/// goes through the real adapter: a deposit, fund and stock purchases (one in
/// dollars, booked at the ECB rate of its day), a partial sale, a dividend, a
/// saveback with its purchase, interest, and the rows an import sets aside or
/// names (a card payment, a bond, a saveback with no purchase, a short row).
/// Every name, id and figure is made up; the ids are fixed, so importing it
/// twice adds nothing.
String sampleImportCsv(DateTime now) {
  final day = DateTime.utc(now.year, now.month, now.day, 9);
  String ago(int days) =>
      '${day.subtract(Duration(days: days)).toIso8601String().substring(0, 19)}Z';
  const fund = 'XX00QSAMPLE1';
  const stock = 'XX00QSAMPLE2';
  const bond = 'XX00QSAMPLE3';
  return [
    'datetime,category,type,asset_class,name,symbol,shares,price,amount,fee,'
        'tax,currency,transaction_id',
    '${ago(60)},CASH,CUSTOMER_INPAYMENT,,,,,,3000,,,EUR,sample-1',
    '${ago(58)},TRADING,BUY,FUND,Fondo Ejemplo Mundial,$fund,12,100,-1200,-1,,EUR,sample-2',
    '${ago(40)},TRADING,BUY,STOCK,Ejemplo Industrial Corp.,$stock,4,217,-868,-1,,USD,sample-3',
    '${ago(30)},TRADING,SELL,FUND,Fondo Ejemplo Mundial,$fund,2,105.50,211,-1,-0.95,EUR,sample-4',
    '${ago(20)},CASH,DIVIDEND,FUND,Fondo Ejemplo Mundial,$fund,,,7.90,,-1.50,EUR,sample-5',
    '${ago(12)},CASH,BENEFITS_SAVEBACK,,Fondo Ejemplo Mundial,$fund,,,15,,,EUR,sample-6',
    '${ago(10)},TRADING,BUY,FUND,Fondo Ejemplo Mundial,$fund,0.142,105.6338,-15,,,EUR,sample-7',
    '${ago(8)},CASH,INTEREST_PAYMENT,,,,,,2.31,,,EUR,sample-8',
    '${ago(6)},CASH,CARD_TRANSACTION,,Tienda Ejemplo,,,,-24.90,,,EUR,sample-9',
    '${ago(5)},TRADING,BUY,BOND,Bono Ejemplo 2030,$bond,1,99,-99,-1,,EUR,sample-10',
    '${ago(4)},CASH,BENEFITS_SAVEBACK,,,,,,9,,,EUR,sample-11',
    '${ago(3)},TRADING,BUY,FUND',
  ].join('\n');
}

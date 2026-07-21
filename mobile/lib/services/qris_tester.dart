import '../qris/index.dart';
import '../services/qr_render.dart';

class TestResult {
  TestResult(this.name, this.pass, [this.extra]);
  final String name;
  final bool pass;
  final String? extra;
}

class QrisTester {
  static const String danaQris =
      "00020101021126570011ID.DANA.WWW011893600915303023251702090302325170303UMI51440014ID.CO.QRIS.WWW0215ID10265294489570303UMI5204737253033605802ID5914Raol Mukarrozi6015Kota Banjar Bar6105707316304E0BD";

  static Future<List<TestResult>> runAll() async {
    final DANA = danaQris;
    final r = <TestResult>[];
    void A(String name, bool cond, [String? extra]) => r.add(TestResult(name, cond, extra));

    final p = parseQRIS(DANA);
    A("parse merchant name", p.merchantName == "Raol Mukarrozi", p.merchantName);
    A("parse merchant city", p.merchantCity == "Kota Banjar Bar", p.merchantCity);
    A("parse currency 360", p.currency == "360", p.currency);
    A("parse static mode", p.initiationMode == "static", p.initiationMode);
    A("parse CRC valid", p.crcIsValid == true, p.crc);

    final renamed = setMerchantName(DANA, "TOKO NEOBRUTAL");
    A("setMerchantName (TLV 59)", parseQRIS(renamed).merchantName == "TOKO NEOBRUTAL");
    A("rename keeps CRC valid", parseQRIS(renamed).crcIsValid == true);

    final recity = setMerchantCity(DANA, "BANDUNG");
    A("setMerchantCity (TLV 60)", parseQRIS(recity).merchantCity == "BANDUNG");

    final setF = setField(DANA, "59", "WARUNG ABC");
    A("setField tag 59", parseQRIS(setF).merchantName == "WARUNG ABC");

    final dyn = makeString(DANA, nominal: "50000");
    final pd = parseQRIS(dyn);
    A("makeString amount 50000", pd.amount == "50000", pd.amount);
    A("makeString dynamic mode", pd.initiationMode == "dynamic", pd.initiationMode);
    A("makeString CRC valid", pd.crcIsValid == true);

    final dynFee = makeString(DANA, nominal: "75000", fee: "2.5", taxtype: "p");
    A("makeString with fee", parseQRIS(dynFee).amount == "75000");

    final dynRenamed = makeString(renamed, nominal: "100000");
    A("dynamic + renamed amount", parseQRIS(dynRenamed).amount == "100000");
    A("dynamic + renamed name", parseQRIS(dynRenamed).merchantName == "TOKO NEOBRUTAL");

    final reg = MerchantRegistry();
    reg.add("DANA1", qris: DANA, name: "Dana Raol");
    A("MerchantRegistry add/get", reg.get("DANA1")?.merchantName == "Raol Mukarrozi");
    A("MerchantRegistry list", reg.list().length == 1);

    final store = TransactionStore();
    final tx = store.create(qris: DANA, nominal: "120000", customerName: "Budi", description: "Test");
    A("TransactionStore create", tx.status == "pending" && tx.ref.startsWith("RAOL"), tx.ref);
    A("Transaction qrisString dynamic", parseQRIS(tx.qrisString).amount == "120000");
    store.confirm(tx.ref);
    A("TransactionStore confirm", store.get(tx.ref)!.status == "paid");
    A("TransactionStore list", store.list().length >= 1);

    final wh = WebhookReceiver(
      onPayment: (ref, _) {
        final t = store.get(ref);
        if (t != null) {
          t.status = "paid";
          t.paidMethod = "webhook";
        }
      },
    );
    final tx2 = store.create(qris: DANA, nominal: "5000");
    final whRes = wh.handle({"ref": tx2.ref, "status": "paid"});
    A("WebhookReceiver confirm",
        store.get(tx2.ref)!.status == "paid" && whRes["action"] == "confirmed");

    final v = validateQRIS(DANA);
    A("validateQRIS valid", v.valid == true);
    final bad = validateQRIS(DANA.substring(0, DANA.length - 4) + "0000");
    A("validateQRIS detects bad CRC", bad.valid == false);

    final pp = p.pretty();
    A("prettyPrint contains merchant", pp.contains("Raol Mukarrozi"));

    final jpg = await QrRender.toJpg(dynRenamed, size: 480);
    A("render JPG (output file)", jpg.isNotEmpty && jpg.length > 100);

    return r;
  }
}

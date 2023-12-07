import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart';
import 'dart:convert';     // per jsonDecode

DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

/****************************************************************************
 * la gestione di eolico/sole è troppo approssimativa.
 * Il programma funziona supponendo per semplicità che eolico e solare
 * siano attivi sempre il che però non è vero.
 ***************************************************************************/
void main() {
  runApp(const NomeApplicazione());
}

class NomeApplicazione extends StatelessWidget {
  const NomeApplicazione({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'controllore turbina',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PaginaHome(),
    );
  }
}

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  final Uri richiestaURL = Uri.parse("http://kili.aspix.it:8008/statistiche/ultimo");
  // https://stackoverflow.com/questions/51579546/how-to-format-datetime-in-flutter/51579740#51579740
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  var tempo = "ciao";
  var immagine = "immagini/elica.gif";

  var qVento = 0;
  var qSole = 1;

  var vento = ["immagini/senzaVento.png", "immagini/bandiera.png","immagini/tornado.png","immagini/esplosione.gif"];
  var sole = ["immagini/nuvolo.png", "immagini/mezzoSole.png","immagini/sole.png","immagini/esplosione.gif"];

  var etichettaVento = "?";
  var etichettaSole = "?";

  Future<DateTime> recuperaUltimoTempo() async {
    Response res = await get(richiestaURL);
    double percentualeVento = 0;
    double percentualeSole = 0;
    if (res.statusCode == 200) {
      var risposta = jsonDecode(res.body);
      if(risposta["fornitore"]=="0"){
        // 0 sta per solare
        percentualeSole = risposta['corrente']/400*100;
        var f = NumberFormat("###", "it_IT");
        qSole = (percentualeSole/33).round();
        if(qSole>2){
          qSole=2;
        }
        etichettaSole = f.format(percentualeSole);
      }else{
        // 1 sta per eolico
        percentualeVento = risposta['tensione']/5*100;
        var f = NumberFormat("###", "it_IT");
        qVento = (percentualeVento/33).round();
        if(qVento>2){
          qVento=2;
        }
        etichettaVento = f.format(percentualeVento);
      }
      return DateTime.parse(risposta['ts']);
    } else {
      throw "Non riesco a recuperare i dati da kili.";
    }
  }

  _PaginaHomeState(){
    // https://stackoverflow.com/questions/49471063/how-to-run-code-after-some-delay-in-flutter
    Timer.periodic(Duration(seconds: 2), (timer) async {
      var adesso = DateTime.now();
      var ultimo = await recuperaUltimoTempo();
      Duration delta = adesso.difference(ultimo);
      var secondi = delta.inSeconds;
      var corrente = delta.inSeconds;
      setState(() {
        if(secondi>10){
          qVento=3;
          qSole=3;
        }else{
          // qVento=1;
          // qSole=1;
        }
        tempo = dateFormat.format(ultimo);
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("IoT: stato dei sensori"),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:[
              Spacer(),
              Text("ultimo aggiornamento", style: TextStyle(fontSize: 25),),
              Text(tempo, style: TextStyle(fontSize: 35),),
              Spacer(),
              Image(image: AssetImage(vento[qVento])),
              Text(etichettaVento),
              Spacer(),
              Image(image: AssetImage(sole[qSole])),
              Text(etichettaSole),
              Spacer(flex: 3),
            ]
        ),
      ),
    );
  }
}

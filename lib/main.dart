import 'package:flutter/material.dart';
import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart';

void main() {
  // Create a custom exporter with headers
  final headers = {
    //INGESTION KEY HERE VARIABLE
    'signoz-access-token': 'XXXXXXX',
  };

  final exporter = CollectorExporter(
    //enter ingestion url here VARIABLE
    Uri.parse('https://ingest.in.signoz.cloud:443/v1/traces'),
    headers: headers,
  );

  // Set up span processors
  final processor = BatchSpanProcessor(exporter);
  final provider = TracerProviderBase(
    processors: [processor],
    //enter service name here VARIABLE
    resource: Resource( [Attribute.fromString("service.name", "flutter-sample-app")]),
  );

  registerGlobalTracerProvider(provider);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenTelemetry Flutter',
      home: TraceInputPage(),
    );
  }
}

class TraceInputPage extends StatefulWidget {
  @override
  _TraceInputPageState createState() => _TraceInputPageState();
}

class _TraceInputPageState extends State<TraceInputPage> {
  final TextEditingController _controller = TextEditingController();
  final Tracer _tracer = globalTracerProvider.getTracer('instrumentation-name');

  void _createSpan() {
    final inputText = _controller.text;

    // Start a root span
    final rootSpan = _tracer.startSpan('root-span');
    try {
      // Create a child span with the input text
      final childSpan = _tracer.startSpan('child-span', kind: SpanKind.client);
      try {
        // Set attribute for the child span
        childSpan.setAttribute(Attribute.fromString('input.name', inputText));

        // Simulate a remote procedure call (this could be a real async call)
        remoteProcedureCall();

        // Add an event to the child span
        childSpan.addEvent('Processed input: $inputText');
      } catch (e) {
        childSpan.recordException(e);
      } finally {
        childSpan.end();
      }
    } catch (e) {
      // Handle any exceptions that may occur while starting spans
      print('Error creating span: $e');
    } finally {
      // End the root span
      rootSpan.end();
    }
  }

  Future<void> remoteProcedureCall() async {
    final headers = <String, String>{};
    W3CTraceContextPropagator().inject(Context.current, headers, _TextMapSetter());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SigNoz Flutter Sample App',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.deepOrange,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Your Name',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.deepOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepOrange),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepOrange),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _createSpan();
                _controller.clear(); // Clear the input field
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Span',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextMapSetter implements TextMapSetter<Map<String, String>> {
  @override
  void set(Map<String, String> carrier, String key, String value) {
    carrier[key] = value;
  }
}
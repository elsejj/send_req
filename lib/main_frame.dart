import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:send_req/var_settter.dart';

import 'models/httpfile.dart';
import 'models/template.dart';

class MainFrameWidget extends StatelessWidget {
  const MainFrameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var model = Provider.of<TemplateModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(model.filePath),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open_outlined),
            tooltip: '打开HTTP文件',
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom, allowedExtensions: ['http', 'txt']);

              final path = result?.files.single.path ?? '';
              if (path.isEmpty) {
                return;
              }

              // set the file path, this will trigger the model to load the file
              model.filePath = path;
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新加载',
            onPressed: () {
              model.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: '发送请求',
            onPressed: () {
              var httpFile = Provider.of<HttpFile>(context, listen: false);
              httpFile.content = model.replaced;
              httpFile.executeSync();
            },
          ),
        ],
      ),
      body: _buildBody(model),
    );
  }

  Widget _buildBody(TemplateModel model) {
    if (model.loaded) {
      return _buildMainContent(model);
    } else {
      return _buildOpenTips();
    }
  }

  Widget _buildMainContent(TemplateModel model) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: VarSetterWidget(),
        ),
        Expanded(
            child: SelectableText(
          model.replaced,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['Consolas', 'monospace'],
          ),
        )),
        Expanded(
            child: Consumer<HttpFile>(
          builder: (context, value, child) => SelectableText(
            value.result,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontFamilyFallback: ['Consolas', 'monospace'],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildOpenTips() {
    return const Center(
      child: Text('点击右下角按钮打开文件'),
    );
  }
}

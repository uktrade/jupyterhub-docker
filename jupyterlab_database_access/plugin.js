import {
  DisposableDelegate
} from '@phosphor/disposable';

import {
  ToolbarButton
} from '@jupyterlab/apputils';

import {
  NotebookActions
} from '@jupyterlab/notebook';

export default {
  activate: (app) => {
    app.docRegistry.addWidgetExtension('Notebook', new ButtonExtension());
  },
  id: 'jupyterlab_database_access:connectButtonPlugin',
  autoStart: true
};

class ButtonExtension {
  createNew(panel, context) {
    const onClick = () => {
      const notebook = panel.content;
      const model = notebook.model;
      const cell = model.contentFactory.createCodeCell({
        cell: {
          source: code[model.defaultKernelName],
          metadata: {
            trusted: true
          }
        }
      });
      model.cells.insert(notebook.activeCellIndex, cell);
      notebook.activeCellIndex--;
      notebook.widgets[notebook.activeCellIndex].inputHidden = true;
      NotebookActions.runAndAdvance(notebook, context.session);
      cell.inputHidden = true;
    };
    const button = new ToolbarButton({
      iconClassName: 'fa fa-database',
      onClick: onClick,
      tooltip: 'Connect to databases'
    });

    panel.toolbar.insertItem(9, 'connectToDatabases', button);
    return new DisposableDelegate(() => {
      button.dispose();
    });
  }
}

const code = {
  'ir': [
    'library(DBI)',
    'con <- dbConnect(odbc::odbc(), "TiVA")',
    'print("You now have 1 database connection")',
    'print("  con")'
  ].join('\n'),
  'python3': [
    'from os import environ as __environ',
    'from collections import namedtuple as __namedtuple',
    'from psycopg2 import connect as __connect',
    '__dsns = dict((key.split("__")[1], __connect(value)) for (key, value) in __environ.items() if key.startswith("DATABASE_DSN__"))',
    'conn = __namedtuple("Connections", __dsns.keys())(**__dsns)',
    'print("You now have {} database connection{}:".format(len(__dsns.keys()), "s" if len(__dsns.keys()) > 1 else ""))',
    'for key in __dsns.keys():',
    '  print(f"  conn.{key}")',
    'del __dsns',
    'del __environ',
    'del __namedtuple',
    'del __connect'
  ].join('\n')
}
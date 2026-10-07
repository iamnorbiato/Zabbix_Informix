<?php
(new CWidgetView($data))
    ->addItem(
        (new CDiv())
            ->addClass('informix-sql-top-n-layout')
            ->addItem([
                (new CDiv())->addClass('informix-sql-top-n-table'),
                (new CDiv())->addClass('informix-sql-top-n-detail')
            ])
    )
    ->setVar('rows', $data['rows'])
    ->setVar('fields_values', $data['fields_values'])
    ->show();

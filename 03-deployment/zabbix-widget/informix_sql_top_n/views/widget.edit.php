<?php
(new CWidgetFormView($data))
    ->addField(new CWidgetFieldMultiSelectItemView($data['fields']['itemid']))
    ->addField(new CWidgetFieldNumericBoxView($data['fields']['preview_width']))
    ->show();

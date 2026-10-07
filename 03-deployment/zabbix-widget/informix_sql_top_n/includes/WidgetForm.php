<?php
namespace Modules\InformixSqlTopN\Includes;

use Zabbix\Widgets\{CWidgetField, CWidgetForm};
use Zabbix\Widgets\Fields\{CWidgetFieldMultiSelectItem, CWidgetFieldNumericBox, CWidgetFieldSelect};

class WidgetForm extends CWidgetForm {
    public function addFields(): self {
        return $this->addField(
            (new CWidgetFieldMultiSelectItem('itemid', _('Master item')))
                ->setFlags(CWidgetField::FLAG_NOT_EMPTY | CWidgetField::FLAG_LABEL_ASTERISK)
                ->setMultiple(false)
        )->addField(
            (new CWidgetFieldNumericBox('preview_width', _('SQL preview width (px)')))
                ->setDefault(320)
                ->setFlags(CWidgetField::FLAG_NOT_EMPTY)
        )->addField(
            (new CWidgetFieldSelect('metric', _('Top-N metric'), [
                0 => _('Maximum runtime'),
                1 => _('Total executions'),
                2 => _('Average time'),
                3 => _('Disk reads'),
                4 => _('Buffer reads'),
                5 => _('Cache ratio'),
                6 => _('Lock waits'),
                7 => _('Lock wait time'),
                8 => _('I/O waits'),
                9 => _('Disk sorts'),
                10 => _('Memory sorts'),
                11 => _('Estimated cost'),
                12 => _('Estimated rows'),
                13 => _('Actual rows'),
                14 => _('Read/write ratio')
            ]))->setDefault(0)
        );
    }
}

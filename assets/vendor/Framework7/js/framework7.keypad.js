/**
 * Framework7 Keypad 1.0.3
 * Keypad plugin extends Framework7 with additional custom keyboards
 * 
 * http://www.idangero.us/framework7/plugins/
 * 
 * Copyright 2015, Vladimir Kharlampidi
 * The iDangero.us
 * http://www.idangero.us/
 * 
 * Licensed under MIT
 * 
 * Released on: August 22, 2015
 */
Framework7.prototype.plugins.keypad = function (app) {
    'use strict';
    var $ = window.Dom7;
    var t7 = window.Template7;
    
    var Keypad = function (params) {
        var p = this;
        
        var defaults = {
            type: 'numpad', //or 'calculator' or 'custom',
            valueMaxLength: null,
            dotButton: true,
            dotCharacter: '.',
            buttons: (function () {
                var dotCharacter = params.dotCharacter || '.';
                if (typeof params.type === 'undefined' || params.type === 'numpad') {
                    // numpad
                    var dotButton = params.dotButton === undefined ? true : params.dotButton;
                    return [
                        {
                            html: '<span class="picker-keypad-button-number">1</span><span class="picker-keypad-button-letters"></span>',
                            value: 1
                        },
                        {
                            html: '<span class="picker-keypad-button-number">2</span><span class="picker-keypad-button-letters">ABC</span>',
                            value: 2
                        },
                        {
                            html: '<span class="picker-keypad-button-number">3</span><span class="picker-keypad-button-letters">DEF</span>',
                            value: 3
                        },
                        {
                            html: '<span class="picker-keypad-button-number">4</span><span class="picker-keypad-button-letters">GHI</span>',
                            value: 4
                        },
                        {
                            html: '<span class="picker-keypad-button-number">5</span><span class="picker-keypad-button-letters">JKL</span>',
                            value: 5
                        },
                        {
                            html: '<span class="picker-keypad-button-number">6</span><span class="picker-keypad-button-letters">MNO</span>',
                            value: 6
                        },
                        {
                            html: '<span class="picker-keypad-button-number">7</span><span class="picker-keypad-button-letters">PQRS</span>',
                            value: 7
                        },
                        {
                            html: '<span class="picker-keypad-button-number">8</span><span class="picker-keypad-button-letters">TUV</span>',
                            value: 8
                        },
                        {
                            html: '<span class="picker-keypad-button-number">9</span><span class="picker-keypad-button-letters">WXYZ</span>',
                            value: 9
                        },
                        {
                            html: dotButton ? '<span class="picker-keypad-button-number">' + dotCharacter + '</span>' : '',
                            value: dotButton ? dotCharacter : undefined,
                            dark: true,
                            cssClass: dotButton ? '' : 'picker-keypad-dummy-button'
                        },
                        {
                            html: '<span class="picker-keypad-button-number">0</span>',
                            value: 0
                        },
                        {
                            html: '<i class="icon icon-keypad-delete"></i>',
                            cssClass: 'picker-keypad-delete',
                            dark: true
                        },  
                    ];
                }
                else if (params.type === 'calculator') {
                    // calculator
                    return [
                        {
                            html: '<span class="picker-keypad-button-number">C</span>',
                            value: 'C',
                            dark:true,
                        },
                        {
                            html: '<span class="picker-keypad-button-number">±</span>',
                            value: '±',
                            dark:true,
                        },
                        {
                            html: '<span class="picker-keypad-button-number">%</span>',
                            value: '%',
                            dark:true,
                        },
                        {
                            html: '<span class="picker-keypad-button-number">÷</span>',
                            value: '÷',
                            cssClass: 'calc-operator-button'

                        },
                        {
                            html: '<span class="picker-keypad-button-number">7</span>',
                            value: 7
                        },
                        {
                            html: '<span class="picker-keypad-button-number">8</span>',
                            value: 8
                        },
                        {
                            html: '<span class="picker-keypad-button-number">9</span>',
                            value: 9
                        },
                        {
                            html: '<span class="picker-keypad-button-number">×</span>',
                            value: '×',
                            cssClass: 'calc-operator-button'
                        },
                        {
                            html: '<span class="picker-keypad-button-number">4</span>',
                            value: 4
                        },
                        {
                            html: '<span class="picker-keypad-button-number">5</span>',
                            value: 5
                        },
                        {
                            html: '<span class="picker-keypad-button-number">6</span>',
                            value: 6
                        },
                        {
                            html: '<span class="picker-keypad-button-number">-</span>',
                            value: '-',
                            cssClass: 'calc-operator-button'
                        },
                        {
                            html: '<span class="picker-keypad-button-number">1</span>',
                            value: 1
                        },
                        {
                            html: '<span class="picker-keypad-button-number">2</span>',
                            value: 2
                        },
                        {
                            html: '<span class="picker-keypad-button-number">3</span>',
                            value: 3
                        },
                        {
                            html: '<span class="picker-keypad-button-number">+</span>',
                            value: '+',
                            cssClass: 'calc-operator-button'
                        },
                        {
                            html: '<span class="picker-keypad-button-number">0</span>',
                            value: 0,
                            cssClass: 'picker-keypad-button-double'
                        },
                        {
                            html: '<span class="picker-keypad-button-number">.</span>',
                            value: dotCharacter
                        },
                        {
                            html: '<span class="picker-keypad-button-number">=</span>',
                            value: '=',
                            cssClass: 'calc-operator-button calc-operator-button-equal'
                        },
                    ];
                }
                else {
                    // custom
                    return [];
                }
            })(),
            // Common settings
            closeByOutsideClick: true,
            scrollToInput: true,
            inputReadOnly: true,
            convertToPopover: true,
            onlyInPopover: false,
            toolbar: true,
            toolbarCloseText: 'Done',
            toolbarTemplate: 
                '<div class="toolbar">' +
                    '<div class="toolbar-inner">' +
                        '<div class="left"></div>' +
                        '<div class="right">' +
                            '<a href="#" class="link close-picker">{{closeText}}</a>' +
                        '</div>' +
                    '</div>' +
                '</div>'
        };
        params = params || {};
        for (var def in defaults) {
            if (typeof params[def] === 'undefined') {
                params[def] = defaults[def];
            }
        }
        p.params = params;
        p.cols = [];
        p.initialized = false;
        
        // Inline flag
        p.inline = p.params.container ? true : false;

        // 3D Transforms origin bug, only on safari
        var originBug = app.device.ios || (navigator.userAgent.toLowerCase().indexOf('safari') >= 0 && navigator.userAgent.toLowerCase().indexOf('chrome') < 0) && !app.device.android;

        // Should be converted to popover
        function isPopover() {
            var toPopover = false;
            if (!p.params.convertToPopover && !p.params.onlyInPopover) return toPopover;
            if (!p.inline && p.params.input) {
                if (p.params.onlyInPopover) toPopover = true;
                else {
                    if (app.device.ios) {
                        toPopover = app.device.ipad ? true : false;
                    }
                    else {
                        if ($(window).width() >= 768) toPopover = true;
                    }
                }
            } 
            return toPopover; 
        }
        function inPopover() {
            if (p.opened && p.container && p.container.length > 0 && p.container.parents('.popover').length > 0) return true;
            else return false;
        }
        // Calculator
        var calcValues = [];
        var calcOperations = [];
        var lastWasNumber = false;
        p.calculator = function (value) {
            var operators = ('+ - = × ÷ ± %').split(' ');
            var numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, '.'];
            var reset = 'C';
            var invert = '±';
            var perc = '%';
            function calc () {
                var toEval = '';
                for (var i = 0; i < calcOperations.length; i++) {
                    var operation = calcOperations[i];
                    if (i === calcOperations.length - 1 && operators.indexOf(operation) >= 0) {

                    }
                    else if (operation) {
                        if (operation === '.') {
                            operation = 0;
                        }
                        toEval += (operation.toString() + '')
                                    .replace('×', '*')
                                    .replace('÷', '/');
                    }
                }
                toEval = toEval.replace(/--/g, '+');
                p.setValue(eval.call(window, toEval));
            }
            if (!p.value) p.value = 0;
            if (value === reset) {
                p.setValue(0);
                calcValues = [];
                calcOperations = [];
                return;
            }
            if (numbers.indexOf(value) >= 0) {
                if (value === '.') {
                    if (lastWasNumber && p.value.toString().indexOf('.') >= 0) return;
                }
                if (operators.indexOf(calcValues[calcValues.length - 1]) >= 0) {
                    p.setValue(value);
                }
                else {
                    p.setValue(p.value ? p.value + '' + value : value);
                }
                lastWasNumber = true;
            }
            if (operators.indexOf(value) >= 0) {
                if (value === invert) {
                    if (p.value === '.') return;
                    p.setValue(-1 * p.value);
                    lastWasNumber = true;
                }
                else if (value === perc) {
                    if (calcOperations[calcOperations.length - 2]) {
                        var percents = p.value / 100;
                        p.setValue(calcOperations[calcOperations.length - 2] * percents);
                    }
                    lastWasNumber = true;
                }
                else {
                    var lastOperation = calcOperations[calcOperations.length - 1];
                    if (value === '=') {
                        if (calcOperations[calcOperations.length - 1] === '=') {
                            if (calcOperations.length < 2) return;
                            calcOperations.pop();
                            var val1 = calcOperations[calcOperations.length - 2];
                            var val2 = calcOperations[calcOperations.length - 1];
                            calcOperations.push(val1);
                            calcOperations.push(val2); 
                        }
                        else {
                            calcOperations.push(p.value);
                        }
                        calcOperations.push('=');   
                        calc();
                    }
                    else if (['-', '+', '×', '÷', '='].indexOf(lastOperation) >= 0) {
                        if (lastOperation === '=') {
                            calcOperations = [p.value, value];
                        }
                        if (['-', '+', '×', '÷'].indexOf(lastOperation) >= 0) {
                            if (lastWasNumber) {
                                if (['-', '+'].indexOf(lastOperation) >= 0 && ['×', '÷'].indexOf(value) >= 0) {
                                    calcOperations.push(p.value);
                                    calcOperations.push(value);
                                }
                                else {
                                    calcOperations.push(p.value);
                                    calcOperations.push(value);
                                    calc();
                                }
                            }
                            else {
                                calcOperations[calcOperations.length - 1] = value;   

                            }
                        }
                    }
                    
                    else {
                        calcOperations.push(p.value);
                        calcOperations.push(value);
                        calc();
                    }
                    lastWasNumber = false;
                }
            }
            if (value !== invert && value !== perc) calcValues.push(value);
        };
        // Value
        p.setValue = function (value) {
            p.updateValue(value);
        };
        p.updateValue = function (newValue) {
            p.value = newValue;
            if (p.params.valueMaxLength && p.value.length > p.params.valueMaxLength) {
                p.value = p.value.substring(0, p.params.valueMaxLength);
            }
            if (p.params.onChange) {
                p.params.onChange(p, p.value);
            }
            if (p.input && p.input.length > 0) {
                $(p.input).val(p.params.formatValue ? p.params.formatValue(p, p.value) : p.value);
                $(p.input).trigger('change');
            }
        };

        // Columns Handlers
        p.initKeypadEvents = function () {
            var buttonsContainer = p.container.find('.picker-keypad-buttons');

            function handleClick(e) {
                var buttonContainer = $(e.target);
                if (!buttonContainer.hasClass('picker-keypad-button')) {
                    buttonContainer = buttonContainer.parents('.picker-keypad-button');
                }
                if (buttonContainer.length === 0) return;
                var button = p.params.buttons[buttonContainer.index()];
                var buttonValue = button.value;
                var currentValue = p.value;

                if (p.params.type === 'numpad') {
                    if (typeof currentValue === 'undefined') currentValue = '';
                    if (buttonContainer.hasClass('picker-keypad-delete')) {
                        currentValue = currentValue.substring(0, currentValue.length - 1);
                    }
                    else {
                        if (typeof buttonValue !== 'undefined') {
                            if (buttonValue === '.' && currentValue.indexOf('.') >= 0) {
                                buttonValue = '';
                            }
                            currentValue += buttonValue;
                        }
                    }
                    if (typeof currentValue !== 'undefined') p.setValue(currentValue);
                }
                if (p.params.type === 'calculator') {
                    p.calculator(button.value);
                    buttonsContainer.find('.calc-operator-active').removeClass('calc-operator-active');
                    if (buttonContainer.hasClass('calc-operator-button') && !buttonContainer.hasClass('calc-operator-button-equal')) {
                        buttonContainer.addClass('calc-operator-active');
                    }
                }
                if (p.params.type === 'custom') {

                }
                if (button.onClick) {
                    button.onClick(p, button);
                }
            }

            buttonsContainer.on('click', handleClick);

            p.container[0].f7DestroyKeypadEvents = function () {
                buttonsContainer.off('click', handleClick);
            };

        };
        p.destroyKeypadEvents = function (colContainer) {
            if ('f7DestroyKeypadEvents' in p.container[0]) p.container[0].f7DestroyKeypadEvents();
        };

        // HTML Layout
        p.buttonsHTML = function () {
            var buttonsHTML = '', buttonClass, button;
            for (var i = 0; i < p.params.buttons.length; i++) {
                button = p.params.buttons[i];
                buttonClass = 'picker-keypad-button';
                if (button.dark) buttonClass += ' picker-keypad-button-dark';
                if (button.cssClass) buttonClass += ' ' + button.cssClass;
                buttonsHTML += '<span class="' + buttonClass + '">' + (button.html || '') + '</span>';
            }
            return buttonsHTML;
        };
        p.layout = function () {
            var pickerHTML = '';
            var pickerClass = '';
            var i;
            var buttonsHTML = p.buttonsHTML();
            pickerClass = 'picker-modal picker-keypad picker-keypad-type-' + p.params.type + ' ' + (p.params.cssClass || '');
            pickerHTML =
                '<div class="' + (pickerClass) + '">' +
                    (p.params.toolbar ? p.params.toolbarTemplate.replace(/{{closeText}}/g, p.params.toolbarCloseText) : '') +
                    '<div class="picker-modal-inner picker-keypad-buttons">' +
                        buttonsHTML +
                    '</div>' +
                '</div>';
                
            p.pickerHTML = pickerHTML;    
        };

        // Input Events
        function openOnInput(e) {
            e.preventDefault();
            if (p.opened) return;
            p.open();
            if (p.params.scrollToInput && !isPopover()) {
                var pageContent = p.input.parents('.page-content');
                if (pageContent.length === 0) return;

                var paddingTop = parseInt(pageContent.css('padding-top'), 10),
                    paddingBottom = parseInt(pageContent.css('padding-bottom'), 10),
                    pageHeight = pageContent[0].offsetHeight - paddingTop - p.container.height(),
                    pageScrollHeight = pageContent[0].scrollHeight - paddingTop - p.container.height(),
                    newPaddingBottom;
                var inputTop = p.input.offset().top - paddingTop + p.input[0].offsetHeight;
                if (inputTop > pageHeight) {
                    var scrollTop = pageContent.scrollTop() + inputTop - pageHeight;
                    if (scrollTop + pageHeight > pageScrollHeight) {
                        newPaddingBottom = scrollTop + pageHeight - pageScrollHeight + paddingBottom;
                        if (pageHeight === pageScrollHeight) {
                            newPaddingBottom = p.container.height();
                        }
                        pageContent.css({'padding-bottom': (newPaddingBottom) + 'px'});
                    }
                    pageContent.scrollTop(scrollTop, 300);
                }
            }
        }
        function closeOnHTMLClick(e) {
            if (inPopover()) return;
            if (p.input && p.input.length > 0) {
                if (e.target !== p.input[0] && $(e.target).parents('.picker-modal').length === 0) {
                    p.close();
                }
            }
            else {
                if ($(e.target).parents('.picker-modal').length === 0) p.close();   
            }
        }

        if (p.params.input) {
            p.input = $(p.params.input);
            if (p.input.length > 0) {
                if (p.params.inputReadOnly) p.input.prop('readOnly', true);
                if (!p.inline) {
                    p.input.on('click', openOnInput);    
                }
                if (p.params.inputReadOnly) {
                    p.input.on('focus mousedown', function (e) {
                        e.preventDefault();
                    });
                }
            }
        }
        
        if (!p.inline && p.params.closeByOutsideClick) $('html').on('click', closeOnHTMLClick);

        // Open
        function onPickerClose() {
            p.opened = false;
            if (p.input && p.input.length > 0) {
                p.input.parents('.page-content').css({'padding-bottom': ''});
                if (app.params.material) p.input.trigger('blur');
            }
            if (p.params.onClose) p.params.onClose(p);

            // Destroy events
            p.container.find('.picker-items-col').each(function () {
                p.destroyPickerCol(this);
            });
        }

        p.opened = false;
        p.open = function () {
            var toPopover = isPopover();

            if (!p.opened) {

                // Layout
                p.layout();

                // Append
                if (toPopover) {
                    p.pickerHTML = '<div class="popover popover-picker-keypad"><div class="popover-inner">' + p.pickerHTML + '</div></div>';
                    p.popover = app.popover(p.pickerHTML, p.params.input, true);
                    p.container = $(p.popover).find('.picker-modal');
                    $(p.popover).on('close', function () {
                        onPickerClose();
                    });
                }
                else if (p.inline) {
                    p.container = $(p.pickerHTML);
                    p.container.addClass('picker-modal-inline');
                    $(p.params.container).append(p.container);
                }
                else {
                    p.container = $(app.pickerModal(p.pickerHTML));
                    $(p.container)
                    .on('close', function () {
                        onPickerClose();
                    });
                }

                // Store picker instance
                p.container[0].f7Keypad = p;

                // Init Events
                p.initKeypadEvents();
                
                // Set value
                if (!p.initialized) {
                    if (p.params.value) {
                        p.setValue(p.params.value);
                    }
                }
                else {
                    if (p.value) p.setValue(p.value);
                }

                // Material Focus
                if (p.input && p.input.length > 0 && app.params.material) {
                    p.input.trigger('focus');
                }
            }

            // Set flag
            p.opened = true;
            p.initialized = true;

            if (p.params.onOpen) p.params.onOpen(p);
        };

        // Close
        p.close = function () {
            if (!p.opened || p.inline) return;
            if (inPopover()) {
                app.closeModal(p.popover);
                return;
            }
            else {
                app.closeModal(p.container);
                return;
            }
        };

        // Destroy
        p.destroy = function () {
            p.close();
            if (p.params.input && p.input.length > 0) {
                p.input.off('click focus', openOnInput);
            }
            $('html').off('click', closeOnHTMLClick);
        };

        if (p.inline) {
            p.open();
        }

        return p;
    };
    
    app.keypad = function (params) {
        return new Keypad(params);
    };
    function pageInit(page) {
        $(page.container).find('input[type="numpad"], input[type="calculator"]').each(function () {
            var input = $(this);
            input[0].f7Keypad = new Keypad({
                input: input,
                type: input.attr('type'),
                value: input.val() || 0,
                valueMaxLength: input.attr('maxlength') || undefined,
                toolbar: input.attr('data-toolbar') === 'false' ? false : true,
                toolbarCloseText: input.attr('data-toolbarCloseText') || undefined
            });
        });
        $(page.container).find('.numpad-init, .calculator-init').each(function () {
            var inline = $(this);
            var type;
            if (inline.hasClass('calculator-init')) type = 'calculator';
            if (inline.hasClass('numpad-init')) type = 'numpad';
            inline[0].f7Keypad = new Keypad({
                input: inline.attr('data-input') || undefined,
                type: type,
                value: inline.attr('data-value') || undefined,
                valueMaxLength: input.attr('maxlength') || undefined,
                toolbar: input.attr('data-toolbar') === 'false' ? false : true,
                toolbarCloseText: input.attr('data-toolbarCloseText') || undefined
            });
        });
    }
    
    return {
        hooks : {
            pageInit: pageInit,
        }
    };
};
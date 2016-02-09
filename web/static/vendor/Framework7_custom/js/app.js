var $$ = Dom7;

var exMoney = new Framework7({
  modalTitle: 'ExMoney',

  onAjaxStart: function (xhr) {
    exMoney.showIndicator();
  },
  onAjaxComplete: function (xhr) {
    exMoney.hideIndicator();
  },

  onPageInit: function(app, page) {
    if (page.name == 'login-screen') {
      $$('#login-form').on('submitted', function (e) {
        var xhr = e.detail.xhr;

        if (xhr.status == 200) {
          window.location.replace("/m");
        } else {
          exMoney.alert(xhr.responseText);
        }
      });

      $$('#login-form').on('submitError', function (e) {
        var xhr = e.detail.xhr;

        exMoney.alert(xhr.responseText);
      });
    }

    if (page.name == 'embedded-login-screen') {
      $$('#embedded-login-form').on('submitted', function (e) {
        var xhr = e.detail.xhr;

        if (xhr.status == 200) {
          exMoney.closeModal($$(".embedded-login-screen"));
          mainView.router.load({ url: '/m/dashboard' });
        } else {
          exMoney.alert(xhr.responseText);
        }
      });

      $$('#login-form').on('submitError', function (e) {
        var xhr = e.detail.xhr;

        exMoney.alert(xhr.responseText);
      });
    }

    if (page.name == 'overview-screen') {
      $$('.swipeout').on('deleted', function (e) {
        var id = $$(e.target).children("div.swipeout-actions-opened").find("a.delete-transaction").data('id');
        var csrf = document.querySelector("meta[name=csrf]").content;

        $$.ajax({
          url: '/m/transactions/' + id + "?_format=json",
          contentType: "application/json",
          type: 'DELETE',
          headers: {
            "X-CSRF-TOKEN": csrf
          },
          success: function(data, status, xhr) {
            var response = JSON.parse(data);
            $$("#account_id_" + response.account_id).text(response.new_balance);
          },
          error: function(xhr, status) {
            alert("Something went wrong, check server logs");
          }
        });
      });
    }
  }
});

var mainView = exMoney.addView('.view-main');

exMoney.onPageBeforeInit('edit-transaction-screen', function (page) {
  $$('form.ajax-submit').on('submitted', function (e) {
    var xhr = e.detail.xhr;

    if (xhr.status == 200) {
      mainView.router.back({
        url: '/m/dashboard',
        ignoreCache: true,
        force: true
      });
    } else {
      exMoney.alert(xhr.responseText);
    }
  });
});

exMoney.onPageBeforeInit('new-transaction-screen', function (page) {
  var calculator = exMoney.keypad({
    input: '#new-transaction-amount',
    toolbar: false,
    type: 'calculator'
  });

  calculator.open();

  var calendar = exMoney.calendar({
    input: '#transaction_made_on',
    toolbar: false,
    scrollToInput: false,
    closeOnSelect: true,
    value: [new Date()]
  });

  $$('form.ajax-submit').on('submitted', function (e) {
    var xhr = e.detail.xhr;

    if (xhr.status == 200) {
      mainView.router.back({
        url: '/m/dashboard',
        ignoreCache: true,
        force: true
      });
    } else {
      exMoney.alert(xhr.responseText);
    }
  });

  $$('a#expense-button').on('click', function (e) {
    $$('a#expense-button').addClass('active');
    $$('a#income-button').removeClass('active');
    $$('#transaction_type').val('expense');
  });

  $$('a#income-button').on('click', function (e) {
    $$('a#income-button').addClass('active');
    $$('a#expense-button').removeClass('active');
    $$('#transaction_type').val('income');
  });
});

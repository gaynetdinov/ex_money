import "phoenix_html"
import socket from "./socket"

import Framework7 from 'framework7';
import Framework7Keypad from 'framework7-plugin-keypad';

Framework7.use(Framework7Keypad);

var $$ = Dom7;

function adjustSelectedCategory() {
  var category = $$('a.smart-select div.item-content div.item-inner div.item-after');
  category.text(category.text().replace(/\u21b3/g, ""));
};

function deleteTransaction() {
  $$('.tr-li').on('swipeout:deleted', function (e) {
    var id = $$(e.target).children("div.swipeout-actions-opened").find("a.delete-transaction").data('id');
    var csrf = document.querySelector("meta[name=csrf]").content;

    Framework7.request({
      url: '/m/transactions/' + id + "?_format=json",
      contentType: "application/json",
      type: 'DELETE',
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      success: function(data, status, xhr) {
        var response = JSON.parse(data);
        if (response.new_balance) {
          $$("#account_id_" + response.account_id).text(response.new_balance);
        }
      },
      error: function(xhr, status) {
        alert("Something went wrong, check server logs");
      }
    });
  });
}

function setToken(jwt) {
  var token = {value: jwt, timestamp: new Date().getTime()};
  localStorage.setItem("token", JSON.stringify(token));
}

function socketConnect(jwt) {
  var socket = new window.Socket("/refresh_socket", {params: {guardian_token: jwt}});
  socket.connect();

  var channel = socket.channel("login_refresh:interactive", {});

  channel.join()
    .receive("error", function(resp) { exMoney.alert('Could not connect to WebSocket channel') });

  window.channel = channel;

  applyBindings(window.channel);
}

function applyBindings(channel) {
  channel.on("refresh_request_ok", function(data) {
    exMoney.showPreloader([data.msg]);
  })

  channel.on("refresh_request_failed", function(data) {
    var account_id = $$("#account-refresh-content").data("account-id");
    exMoney.alert(data.msg, function() {
      mainView.router.back({url: '/m/accounts/' + account_id});
    });
  });

  channel.on("ask_otp", function(data) {
    exMoney.hidePreloader();

    var login_id = $$("#account-refresh-content").data("login-id");
    var account_id = $$("#account-refresh-content").data("account-id");
    var interactive = {status: true, account_id: account_id};
    localStorage.setItem("interactive", JSON.stringify(interactive));
    exMoney.prompt('Please enter OTP', 'One Time Password',
      function(value) {
        channel.push("send_otp", {otp: value, login_id: login_id, field: data.field});
        localStorage.setItem("interactive", JSON.stringify({status: false}));
      },
      function(value) {
        channel.push("cancel_otp", {});
        localStorage.setItem("interactive", JSON.stringify({status: false}));
        mainView.router.back({url: '/m/accounts/' + account_id});
      }
    );
  });

  channel.on("not_supported_otp", function(data) {
    exMoney.hidePreloader();
    localStorage.setItem("interactive", JSON.stringify({status: false}));
    exMoney.alert(data.msg);
  });

  channel.on("otp_sent", function(data) {
    var account_id = $$("#account-refresh-content").data("account-id");
    exMoney.alert(data.title, data.msg, function () {
      localStorage.setItem("interactive", JSON.stringify({status: false}));
      mainView.router.back({
        url: '/m/accounts/' + account_id,
        ignoreCache: true,
        force: true
      });
    });
  });

  channel.on("transactions_fetched", function(msg) {
    exMoney.addNotification({title: msg.title, message: msg.message});
  });
}

var exMoney = new Framework7({
  root: '#app',
  modalTitle: 'ExMoney',
  id: 'com.exmoney',
  theme: 'ios',
  //statusbar: { iosOverlaysWebview: true },
  touch: { tapHold: true },
  panel: { swipe: 'left' },
  routes: [
    {
      name: 'start-screen',
      path: '/m',
      url: '/m',
      on: {
        pageInit: function (e, page) {
          var router = this;

          Framework7.request({
            url: '/m/logged_in',
            type: 'GET',
            complete: function(xhr, status) {
              window.location.replace('/m/dashboard');
            },
            error: function(xhr, status) {
              if (localStorage.token) {
                var jwt = JSON.parse(localStorage.token).value;

                Framework7.request({
                  url: '/api/v1/session/relogin',
                  type: 'GET',
                  contentType: 'application/json',
                  headers: {
                    'Authorization': jwt
                  },
                  error: function(xhr, status) {
                    alert('Something went wrong');
                  },
                  complete: function(xhr, status) {
                    setToken(JSON.parse(xhr.response)['token']);
                    //socketConnect(xhr.responseText);

                    if (localStorage.interactive != undefined) {
                      var interactive = JSON.parse(localStorage.interactive);
                      if (interactive.status == true) {
                        router.load({ url: '/m/accounts/' + interactive.account_id + '/refresh' });
                      } else {
                        router.load({ url: '/m/dashboard', animatePages: false, reload: true });
                      }
                    } else {
                      window.location.replace('/m/dashboard');
                    }
                  }
                });
              } else {
                window.location.replace('/m/dashboard');
              }
            }
          });
        }
      }
    },
    {
      name: 'account-screen',
      path: '/m/accounts/:id',
      url: '/m/accounts/{{id}}',
      on: {
        pageInit: function(e, page) {
          var router = this;
          $$('a.category-bar').on('taphold', function() {
            var category_id = $$(this).data("category-id");
            var date = page.route.query.date || $$("#current_date").data("current-date");
            var account_id = $$("#account_id").data("account-id");

            router.navigate({
              url: '/m/transactions?category_id='+category_id+'&date='+date+'&account_id='+account_id,
              ignoreCache: true
            });
          });
        }
      }
    },
    {
      name: 'account-expenses-screen',
      path: '/m/accounts/:id/expenses',
      url: '/m/accounts/{{id}}/expenses',
      on: {
        pageInit: function(e, page) {
          deleteTransaction();
        }
      }
    },
    {
      name: 'account-income-screen',
      path: '/m/accounts/:id/income',
      url: '/m/accounts/{{id}}/income',
      on: {
        pageInit: function(e, page) {
          deleteTransaction();
        }
      }
    },
    {
      name: 'transactions-screen',
      path: '/m/transactions',
      url: '/m/transactions',
      on: {
        pageInit: function(e, page) {
          deleteTransaction();
        }
      }
    },
    {
      name: 'new-transaction-screen',
      path: '/m/transactions/new',
      url: '/m/transactions/new'
    },
    {
      name: 'show-transaction-screen',
      path: '/m/transactions/:id',
      url: '/m/transactions/{{id}}'
    },
    {
      name: 'edit-transaction-screen',
      path: '/m/transactions/:id/edit',
      url: '/m/transactions/{{id}}/edit',
      on: {
        pageInit: function (e, page) {
          setTimeout(function() { adjustSelectedCategory(); }, 50);

          $$('#transaction_category_id').on('change', function(e) {
            setTimeout(function() { adjustSelectedCategory(); }, 50);
          });

          $$('a.back-to-dashboard').on('click', function(e) { exMoney.fab.close('div.fab'); });

          var router = this;
          $$('form.form-ajax-submit').on('formajax:complete', function (e, formData, request) {
            if (request.status == 200) {
              router.back({
                url: request.responseText,
                ignoreCache: true,
                force: true
              });
            } else { alert(request.responseText); }
          });
        }
      }
    },
    {
      name: 'dashboard-screen',
      path: '/m/dashboard',
      url: '/m/dashboard',
      on: {
        pageInit: function (e, page) {
          var router = this;
          deleteTransaction();

          $$("#fav_tr_open").on("click", function(e) {
            exMoney.fab.close('div.fab');
            var fav_popup = exMoney.popup.create({el: '#fav_tr_popup'});
            fav_popup.open('#fav_tr_popup', true);

            var csrf = document.querySelector("meta[name=csrf]").content;
            var fav_calculator = exMoney.keypad.create({
              inputEl: '#new-fav-transaction-amount',
              scrollToInput: false,
              type: 'calculator'
            });

            fav_calculator.on('closed', function(keypad) {
              Framework7.request({
                url: '/m/transactions/create_from_fav',
                contentType: "application/json",
                type: 'POST',
                data: JSON.stringify(exMoney.form.convertToData('#fav_tr_form')),
                headers: {
                  "X-CSRF-TOKEN": csrf
                },
                success: function(data, status, xhr) {
                  if (xhr.status == 200) {
                    exMoney.popup.close(fav_tr_popup, false);
                    router.refreshPage();
                  } else {
                    alert(xhr.responseText);
                  }
                },
                error: function(xhr, status) {
                  alert("Something went wrong, check server logs");
                }
              });
            });

            $$('#fav_tr_popup').on('popup:opened', function() {
              fav_calculator.open();
            });
          });
        }
      }
    },
    {
      name: 'login-screen',
      path: '/m/login',
      url: '/m/login',
      on: {
        pageInit: function (e, page) {
          $$('#login-form').on('formajax:complete', function (e, formData, request) {
            setToken(JSON.parse(request.response)['token']);
            window.location.replace('/m/dashboard');
          });
        }
      }
    },
    {
      name: 'budget-screen',
      path: '/m/budget',
      url: '/m/budget',
      on: {
        pageInit: function (e, page) {
          console.log('budget init');
        }
      }
    }
  ]
});

var mainView = exMoney.views.create('.view-main', { iosDynamicNavbar: false });

mainView.on('pageInit', function(page) {
  if (page.name == 'new-transaction-screen') {
    var router = this.router;

    $$('#new_transaction_back').on('click', function(e) {
      exMoney.fab.close('div.fab');
    });

    $$('#transaction_category_id').on('change', function(e) {
      setTimeout(function() { adjustSelectedCategory(); }, 50);
    });

    var calculator = exMoney.keypad.create({
      inputEl: '#new-transaction-amount',
      toolbar: false,
      type: 'calculator'
    });

    calculator.open();

    var calendar = exMoney.calendar.create({
      inputEl: '#transaction_made_on',
      toolbar: false,
      scrollToInput: false,
      closeOnSelect: true,
      value: [new Date()]
    });

    $$('form.form-ajax-submit').on('formajax:complete', function (e, formData, request) {
      if (request.status == 200) {
        router.back({
          url: '/m/dashboard',
          ignoreCache: true,
          force: true
        });
      } else {
        alert(request.responseText);
      }
    });

    $$('a#expense-button').on('click', function (e) {
      $$('a#expense-button').addClass('button-active');
      $$('a#income-button').removeClass('button-active');
      $$('#transaction_type').val('expense');
    });

    $$('a#income-button').on('click', function (e) {
      $$('a#income-button').addClass('button-active');
      $$('a#expense-button').removeClass('button-active');
      $$('#transaction_type').val('income');
    });
  }
});

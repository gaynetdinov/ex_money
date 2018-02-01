var $$ = Dom7;

function setToken(jwt) {
  token = {value: jwt, timestamp: new Date().getTime()};
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

function deleteTransaction() {
  $$('.tr-li').on('deleted', function (e) {
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

var exMoney = new Framework7({
  modalTitle: 'ExMoney',
  scrollTopOnNavbarClick: true,
  popupCloseByOutside: false,
  tapHold: true,
  tapHoldDelay: 500,

  onPageInit: function(app, page) {
    if (page.name == 'start-screen') {
      if (localStorage.token) {
        var jwt = JSON.parse(localStorage.token).value;

        $$.ajax({
          url: '/api/v1/session/relogin?_format=json',
          type: 'GET',
          contentType: "application/json",
          headers: {
            "Authorization": jwt
          },
          complete: function(xhr, status) {
            if (xhr.responseText == "Unauthenticated") {
              localStorage.removeItem("token");
              window.location.replace("/m/dashboard");
            }
            else {
              setToken(xhr.responseText);
              socketConnect(xhr.responseText);

              if (localStorage.interactive != undefined) {
                var interactive = JSON.parse(localStorage.interactive);
                if (interactive.status == true) {
                  mainView.router.load({ url: '/m/accounts/' + interactive.account_id + '/refresh' });
                } else {
                  mainView.router.load({ url: '/m/dashboard', animatePages: false, reload: true });
                }
              } else { mainView.router.load({ url: '/m/dashboard', animatePages: false, reload: true }); }
            }
          }
        });
      } else {
        window.location.replace("/m/dashboard");
      }
    }

    if (page.name == 'login-screen') {
      $$('#login-form').on('submitted', function (e) {
        var xhr = e.detail.xhr;

        if (xhr.status == 200) {
          setToken(xhr.responseText);
          socketConnect(xhr.responseText);
          window.location.replace("/m/dashboard");
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
      deleteTransaction();

      $$("#fav_tr_open").on("click", function(e) {
        $$('.speed-dial-opened').removeClass('speed-dial-opened');
        var fav_tr_popup = $$('#fav_tr_popup');
        exMoney.popup(fav_tr_popup);

        var csrf = document.querySelector("meta[name=csrf]").content;
        var fav_calculator = exMoney.keypad({
          input: '#new-fav-transaction-amount',
          scrollToInput: false,
          type: 'calculator',
          onClose: function(p) {
            $$.ajax({
              url: '/m/transactions/create_from_fav',
              contentType: "application/json",
              type: 'POST',
              data: JSON.stringify(exMoney.formToData('#fav_tr_form')),
              headers: {
                "X-CSRF-TOKEN": csrf
              },
              success: function(data, status, xhr) {
                if (xhr.status == 200) {
                  exMoney.closeModal(fav_tr_popup);
                  mainView.router.refreshPage();
                } else {
                  exMoney.alert(xhr.responseText);
                }
              },
              error: function(xhr, status) {
                alert("Something went wrong, check server logs");
              }
            });
          }
        });

        $$('#fav_tr_popup').on('opened', function() {
          fav_calculator.open();
        });
      });
    }
  }
});

var mainView = exMoney.addView('.view-main');

function adjustSelectedCategory() {
  var category = $$('a.smart-category-select div.item-content div.item-inner div.item-after');
  category.text(category.text().replace(/\u21b3/g, ""));
};

exMoney.onPageInit('account-income-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('account-expenses-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('transactions-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('budget-expenses-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('budget-income-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('settings-new-budget-page', function(page) {
  var items = $$("#budget_items");
  $$('#budget_template_category').on('change', function(e) {
    setTimeout(function() { adjustSelectedCategory(); }, 100);
    var chosen_category = $$(this).find('option:checked');

    $$(
      "<li><div class='item-content'><div class='item-inner'>" +
      "<div class='item-title label'>" + chosen_category.text().replace(/\u21b3/g, '') + "</div>" +
      "<div class='item-input'>" +
      "<input id='budget_item_" + chosen_category.val() + "'" +
      "name='budget_items[" + chosen_category.val() +"]' style='text-align: right' type='text'>" +
      "</div></div></div></li>"
    ).prependTo(items);

    var calculator = exMoney.keypad({
      input: '#budget_item_' + chosen_category.val(),
      toolbar: true,
      type: 'calculator'
    });

    calculator.open();
  });

  $$('.budget-item-li').on('deleted', function (e) {
    var id = $$(e.target).children("div.swipeout-actions-opened").find("a.delete-budget-item").data('id');
    var csrf = document.querySelector("meta[name=csrf]").content;

    $$.ajax({
      url: '/m/settings/budget_items/' + id + "?_format=json",
      contentType: "application/json",
      type: 'DELETE',
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      success: function(data, status, xhr) {},
      error: function(xhr, status) {
        alert("Something went wrong, check server logs");
      }
    });
  });

  $$('form.ajax-submit').on('submitted', function (e) {
    var xhr = e.detail.xhr;

    if (xhr.status == 200) {
      mainView.router.back({
        url: '/m/settings/budget',
        ignoreCache: true,
        force: true
      });
    } else {
      exMoney.alert("Something went wrong, check server logs");
    }
  });
});

exMoney.onPageInit('settings-show-budget-page', function(page) {
  $$('#apply_budget').on('click', function (e) {
    var csrf = document.querySelector("meta[name=csrf]").content;

    $$.ajax({
      url: '/m/settings/budget/apply?_format=json',
      contentType: "application/json",
      type: 'POST',
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      success: function(data, status, xhr) {
        $$('#apply_budget').remove();
        exMoney.alert('The budget has been set for current month');
      },
      error: function(xhr, status) {
        alert("Something went wrong, check server logs");
      }
    });
  });
});

exMoney.onPageInit('settings-edit-budget-page', function(page) {
  $$.each($$('.budget-item-amount'), function(index, value) {
    exMoney.keypad({
      input: value,
      toolbar: true,
      type: 'calculator'
    });
  });

  exMoney.keypad({
    input: '#budget-goal',
    toolbar: true,
    type: 'calculator'
  });

  exMoney.keypad({
    input: '#budget-income',
    toolbar: true,
    type: 'calculator'
  });

  var items = $$("#budget_items");
  $$('#budget_template_category').on('change', function(e) {
    setTimeout(function() { adjustSelectedCategory(); }, 100);
    var chosen_category = $$(this).find('option:checked');

    $$(
      "<li><div class='item-content'><div class='item-inner'>" +
      "<div class='item-title label'>" + chosen_category.text().replace(/\u21b3/g, '') + "</div>" +
      "<div class='item-input'>" +
      "<input class='budget-item-input' id='budget_item_" + chosen_category.val() + "'" +
      "name='budget_items[" + chosen_category.val() +"]' style='text-align: right' type='text'>" +
      "</div></div></div></li>"
    ).prependTo(items);

    var calculator = exMoney.keypad({
      input: '#budget_item_' + chosen_category.val(),
      toolbar: true,
      type: 'calculator'
    });

    calculator.open();
  });

  $$('.budget-item-li').on('deleted', function (e) {
    var id = $$(e.target).children("div.swipeout-actions-opened").find("a.delete-budget-item").data('id');
    var csrf = document.querySelector("meta[name=csrf]").content;

    $$.ajax({
      url: '/m/settings/budget_items/' + id + "?_format=json",
      contentType: "application/json",
      type: 'DELETE',
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      success: function(data, status, xhr) {},
      error: function(xhr, status) {
        alert("Something went wrong, check server logs");
      }
    });
  });

  $$('form.ajax-submit').on('submitted', function (e) {
    var xhr = e.detail.xhr;

    if (xhr.status == 200) {
      mainView.router.back({
        url: '/m/settings/budget',
        ignoreCache: true,
        force: true
      });
    } else {
      exMoney.alert("Something went wrong, check server logs");
    }
  });
});

exMoney.onPageInit('favourite-transactions-screen', function(page) {
  $$('.back').on('click', function(e) {
    $$('.speed-dial-opened').removeClass('speed-dial-opened');
  });

  $$('.fav-transaction').on('click', function (e) {
    var id = $$(this).data('id');
    var swipeout_line = $$(this);
    var csrf = document.querySelector("meta[name=csrf]").content;

    $$.ajax({
      url: '/m/favourite_transactions/' + id + "/fav?_format=json",
      contentType: "application/json",
      type: 'PUT',
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      success: function(data, status, xhr) {
        $$('.item-after').remove();
        $$("<div class='item-after'><i class='f7-icons color-red'>heart</i></div>").insertAfter($$("#fav_tr_"+id));
        exMoney.swipeoutClose($$(swipeout_line.parent().parent()));
      },
      error: function(xhr, status) {
        alert("Something went wrong, check server logs");
      }
    });
  });

  $$('.fav-tr-li').on('deleted', function (e) {
    var id = $$(e.target).children("div.swipeout-actions-opened").find("a.delete-transaction").data('id');
    var csrf = document.querySelector("meta[name=csrf]").content;

    $$.ajax({
      url: '/m/favourite_transactions/' + id + "?_format=json",
      contentType: "application/json",
      type: 'DELETE',
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      success: function(data, status, xhr) {},
      error: function(xhr, status) {
        alert("Something went wrong, check server logs");
      }
    });
  });
});

exMoney.onPageInit('budget-screen', function (page) {
  $$('a.category-bar').on('taphold', function () {
    var category_id = $$(this).data("category-id");
    var date = page.query.date || $$("#current_date").data("current-date");

    mainView.router.load({
      url: '/m/transactions?category_id='+category_id+'&date='+date+'&type=expenses',
      ignoreCache: true
    });
  });
});

exMoney.onPageInit('account-screen', function (page) {
  $$('a.category-bar').on('taphold', function () {
    var category_id = $$(this).data("category-id");
    var date = page.query.date || $$("#current_date").data("current-date");
    var account_id = $$("#account_id").data("account-id");

    mainView.router.load({
      url: '/m/transactions?category_id='+category_id+'&date='+date+'&account_id='+account_id,
      ignoreCache: true
    });
  });
});

exMoney.onPageInit('edit-category-screen', function (page) {
  $$('form.ajax-submit').on('submitted', function (e) {
    var xhr = e.detail.xhr;

    if (xhr.status == 200) {
      mainView.router.back({
        url: '/m/settings/categories',
        ignoreCache: true,
        force: true
      });
    } else {
      exMoney.alert(xhr.responseText);
    }
  });
});

exMoney.onPageInit('edit-transaction-screen', function (page) {
  adjustSelectedCategory();

  $$('#transaction_category_id').on('change', function(e) {
    setTimeout(function() { adjustSelectedCategory(); }, 100);
  });

  $$('form.ajax-submit').on('submitted', function (e) {
    var xhr = e.detail.xhr;

    if (xhr.status == 200) {
      mainView.router.back({
        url: xhr.responseText,
        ignoreCache: true,
        force: true
      });
    } else {
      exMoney.alert(xhr.responseText);
    }
  });
});

exMoney.onPageInit('new-transaction-screen', function (page) {
  adjustSelectedCategory();

  $$('#new_transaction_back').on('click', function(e) {
    $$('.speed-dial-opened').removeClass('speed-dial-opened');
  });

  $$('#transaction_category_id').on('change', function(e) {
    setTimeout(function() { adjustSelectedCategory(); }, 100);
  });

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

exMoney.onPageInit('new-favourite-transaction-screen', function (page) {
  adjustSelectedCategory();

  $$('.back').on('click', function(e) {
    $$('.speed-dial-opened').removeClass('speed-dial-opened');
  });

  $$('#transaction_category_id').on('change', function(e) {
    setTimeout(function() { adjustSelectedCategory(); }, 100);
  });

  $$('form.ajax-submit').on('submitted', function (e) {
    var xhr = e.detail.xhr;

    if (xhr.status == 200) {
      mainView.router.back({
        url: '/m/favourite_transactions',
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

exMoney.onPageInit('account-refresh-screen', function (page) {
  var login_id = $$("#account-refresh-content").data("login-id");

  var channel = window.channel;

  if (localStorage.interactive == undefined || JSON.parse(localStorage.interactive).status == false) {
    channel.push("send_refresh_request", {login_id: login_id});
  }
});

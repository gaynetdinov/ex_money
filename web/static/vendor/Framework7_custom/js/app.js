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

var exMoney = new Framework7({
  modalTitle: 'ExMoney',
  scrollTopOnNavbarClick: true,
  tapHold: true,
  tapHoldDelay: 500,

  onAjaxStart: function (xhr) {
    exMoney.showIndicator();
  },
  onAjaxComplete: function (xhr) {
    exMoney.hideIndicator();
  },

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

    if (page.name == 'embedded-login-screen') {
      $$('#embedded-login-form').on('submitted', function (e) {
        var xhr = e.detail.xhr;
        if (xhr.status == 200) {
          exMoney.closeModal($$(".embedded-login-screen"));
          setToken(xhr.responseText);
          socketConnect(xhr.responseText);
          mainView.router.load({ url: '/m/dashboard' });
          window.history.pushState('m', '', '/m');
        } else {
          exMoney.alert(xhr.responseText);
        }
      });

      $$('#login-form').on('submitError', function (e) {
        var xhr = e.detail.xhr;

        exMoney.alert(xhr.responseText);
      });
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

    if (page.name == 'overview-screen') { deleteTransaction(); }
  }
});

var mainView = exMoney.addView('.view-main');

function adjustSelectedCategory() {
  var category = $$('a.smart-category-select div.item-content div.item-inner div.item-after');
  category.text(category.text().replace(/\u21b3/g, ""));
};

exMoney.onPageInit('income-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('expenses-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('transactions-screen', function(page) {
  deleteTransaction();
});

exMoney.onPageInit('account-screen', function (page) {
  $$('a.category-bar').on('taphold', function () {
    var category_id = $$(this).data("category-id");
    var date = $$("#current_date").data("current-date");
    var account_id = $$("#account_id").data("account-id");

    mainView.router.load({
      url: '/m/transactions?category_id='+category_id+'&date='+date+'&account_id='+account_id,
      ignoreCache: true
    });
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

exMoney.onPageInit('account-refresh-screen', function (page) {
  var login_id = $$("#account-refresh-content").data("login-id");

  var channel = window.channel;

  if (localStorage.interactive == undefined || JSON.parse(localStorage.interactive).status == false) {
    channel.push("send_refresh_request", {login_id: login_id});
  }
});

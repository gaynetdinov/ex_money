import "phoenix_html"
import socket from "./socket"

function setToken(jwt) {
  var token = {value: jwt, timestamp: new Date().getTime()};
  localStorage.setItem("token", JSON.stringify(token));
}

import Framework7 from 'framework7';
var $$ = Dom7;

var exMoney = new Framework7({
  root: '#app',
  modalTitle: 'ExMoney',
  id: 'com.exmoney',
  theme: 'ios',
  pushState: true,
  panel: {
    swipe: 'left',
  },
  routes: [
    {
      name: 'start-screen',
      path: '/m',
      url: '/m',
      on: {
        pageInit: function (e, page) {
          console.log('page init start screen');
          console.log(localStorage.token);
          if (localStorage.token) {
            var jwt = JSON.parse(localStorage.token).value;
            var router = this;
            console.log('if token');

            $$.ajax({
              url: '/api/v1/session/relogin?_format=json',
              type: 'GET',
              contentType: "application/json",
              headers: {
                "Authorization": jwt
              },
              complete: function(xhr, status) {
                console.log('complete');
                if (xhr.responseText == "Unauthenticated") {
                  localStorage.removeItem("token");
                  window.location.replace("/m/dashboard");
                }
                else {
                  setToken(xhr.responseText);
                  //socketConnect(xhr.responseText);

                  if (localStorage.interactive != undefined) {
                    var interactive = JSON.parse(localStorage.interactive);
                    if (interactive.status == true) {
                      router.load({ url: '/m/accounts/' + interactive.account_id + '/refresh' });
                    } else {
                      router.load({ url: '/m/dashboard', animatePages: false, reload: true });
                    }
                  } else { console.log('here'); router.load({ url: '/m/dashboard', animatePages: false, reload: true }); }
                }
              }
            });
          } else {
            console.log('no token');
            window.location.replace("/m/dashboard");
          }
        }
      }
    },
    {
      path: 'dashboard',
      url: '/m/dashboard'
    },
    {
      name: 'login-screen',
      path: '/m/login',
      url: '/m/login',
      on: {
        pageInit: function (e, page) {
          $$('#login-form').on('formajax:complete', function (e, formData, request) {
            setToken(JSON.parse(request.response)['token']);
            window.location.replace("/m/dashboard");
          });
        }
      }
    }
  ]
});

var mainView = exMoney.views.create('.view-main');

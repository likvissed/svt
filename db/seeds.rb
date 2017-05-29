Role.create(
  [
    {
      name: 'admin',
      short_description: 'Администратор',
      long_description: 'Полные права доступа на все модели'
    },
    {
      name: '***REMOVED***_user',
      short_description: 'Пользователь ЛК',
      long_description: 'Пользователь ЛК, от которого пришел запрос на сервер, зарегестрированный на момент получения
  этого запроса в ЛК, имеющий SID и валидное время жизни сессии'
    }
  ]
)

User.create(
  [
    {
      tn: ***REMOVED***,
      fullname: '***REMOVED***',
      role: Role.find_by(name: 'admin')
    },
    {
      tn: 999_999,
      fullname: 'Пользователь ЛК',
      role: Role.find_by(name: '***REMOVED***_user')
    }
  ]
)

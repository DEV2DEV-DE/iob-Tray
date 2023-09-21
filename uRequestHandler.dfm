object RequestHandler: TRequestHandler
  OnCreate = WebModuleCreate
  OnDestroy = WebModuleDestroy
  Actions = <
    item
      Name = 'ActionBroker'
      PathInfo = '/toastMessage'
      OnAction = RequestHandlerActionBrokerAction
    end>
  Height = 271
  Width = 398
  PixelsPerInch = 120
end

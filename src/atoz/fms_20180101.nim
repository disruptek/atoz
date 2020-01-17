
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Firewall Management Service
## version: 2018-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Firewall Manager</fullname> <p>This is the <i>AWS Firewall Manager API Reference</i>. This guide is for developers who need detailed information about the AWS Firewall Manager API actions, data types, and errors. For detailed information about AWS Firewall Manager features, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/fms-chapter.html">AWS Firewall Manager Developer Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/fms/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "fms.ap-northeast-1.amazonaws.com", "ap-southeast-1": "fms.ap-southeast-1.amazonaws.com",
                           "us-west-2": "fms.us-west-2.amazonaws.com",
                           "eu-west-2": "fms.eu-west-2.amazonaws.com", "ap-northeast-3": "fms.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "fms.eu-central-1.amazonaws.com",
                           "us-east-2": "fms.us-east-2.amazonaws.com",
                           "us-east-1": "fms.us-east-1.amazonaws.com", "cn-northwest-1": "fms.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "fms.ap-south-1.amazonaws.com",
                           "eu-north-1": "fms.eu-north-1.amazonaws.com", "ap-northeast-2": "fms.ap-northeast-2.amazonaws.com",
                           "us-west-1": "fms.us-west-1.amazonaws.com",
                           "us-gov-east-1": "fms.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "fms.eu-west-3.amazonaws.com",
                           "cn-north-1": "fms.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "fms.sa-east-1.amazonaws.com",
                           "eu-west-1": "fms.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "fms.us-gov-west-1.amazonaws.com", "ap-southeast-2": "fms.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "fms.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "fms.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "fms.ap-southeast-1.amazonaws.com",
      "us-west-2": "fms.us-west-2.amazonaws.com",
      "eu-west-2": "fms.eu-west-2.amazonaws.com",
      "ap-northeast-3": "fms.ap-northeast-3.amazonaws.com",
      "eu-central-1": "fms.eu-central-1.amazonaws.com",
      "us-east-2": "fms.us-east-2.amazonaws.com",
      "us-east-1": "fms.us-east-1.amazonaws.com",
      "cn-northwest-1": "fms.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "fms.ap-south-1.amazonaws.com",
      "eu-north-1": "fms.eu-north-1.amazonaws.com",
      "ap-northeast-2": "fms.ap-northeast-2.amazonaws.com",
      "us-west-1": "fms.us-west-1.amazonaws.com",
      "us-gov-east-1": "fms.us-gov-east-1.amazonaws.com",
      "eu-west-3": "fms.eu-west-3.amazonaws.com",
      "cn-north-1": "fms.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "fms.sa-east-1.amazonaws.com",
      "eu-west-1": "fms.eu-west-1.amazonaws.com",
      "us-gov-west-1": "fms.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "fms.ap-southeast-2.amazonaws.com",
      "ca-central-1": "fms.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "fms"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateAdminAccount_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateAdminAccount_605929(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateAdminAccount_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the AWS Firewall Manager administrator account. AWS Firewall Manager must be associated with the master account of your AWS organization or associated with a member account that has the appropriate permissions. If the account ID that you submit is not an AWS Organizations master account, AWS Firewall Manager will set the appropriate permissions for the given member account.</p> <p>The account that you associate with AWS Firewall Manager is called the AWS Firewall Manager administrator account. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AWSFMS_20180101.AssociateAdminAccount"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AssociateAdminAccount_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the AWS Firewall Manager administrator account. AWS Firewall Manager must be associated with the master account of your AWS organization or associated with a member account that has the appropriate permissions. If the account ID that you submit is not an AWS Organizations master account, AWS Firewall Manager will set the appropriate permissions for the given member account.</p> <p>The account that you associate with AWS Firewall Manager is called the AWS Firewall Manager administrator account. </p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AssociateAdminAccount_605927; body: JsonNode): Recallable =
  ## associateAdminAccount
  ## <p>Sets the AWS Firewall Manager administrator account. AWS Firewall Manager must be associated with the master account of your AWS organization or associated with a member account that has the appropriate permissions. If the account ID that you submit is not an AWS Organizations master account, AWS Firewall Manager will set the appropriate permissions for the given member account.</p> <p>The account that you associate with AWS Firewall Manager is called the AWS Firewall Manager administrator account. </p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var associateAdminAccount* = Call_AssociateAdminAccount_605927(
    name: "associateAdminAccount", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.AssociateAdminAccount",
    validator: validate_AssociateAdminAccount_605928, base: "/",
    url: url_AssociateAdminAccount_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationChannel_606196 = ref object of OpenApiRestCall_605589
proc url_DeleteNotificationChannel_606198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotificationChannel_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an AWS Firewall Manager association with the IAM role and the Amazon Simple Notification Service (SNS) topic that is used to record AWS Firewall Manager SNS logs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AWSFMS_20180101.DeleteNotificationChannel"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_DeleteNotificationChannel_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Firewall Manager association with the IAM role and the Amazon Simple Notification Service (SNS) topic that is used to record AWS Firewall Manager SNS logs.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_DeleteNotificationChannel_606196; body: JsonNode): Recallable =
  ## deleteNotificationChannel
  ## Deletes an AWS Firewall Manager association with the IAM role and the Amazon Simple Notification Service (SNS) topic that is used to record AWS Firewall Manager SNS logs.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var deleteNotificationChannel* = Call_DeleteNotificationChannel_606196(
    name: "deleteNotificationChannel", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.DeleteNotificationChannel",
    validator: validate_DeleteNotificationChannel_606197, base: "/",
    url: url_DeleteNotificationChannel_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePolicy_606211 = ref object of OpenApiRestCall_605589
proc url_DeletePolicy_606213(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePolicy_606212(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently deletes an AWS Firewall Manager policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AWSFMS_20180101.DeletePolicy"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_DeletePolicy_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes an AWS Firewall Manager policy. 
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_DeletePolicy_606211; body: JsonNode): Recallable =
  ## deletePolicy
  ## Permanently deletes an AWS Firewall Manager policy. 
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var deletePolicy* = Call_DeletePolicy_606211(name: "deletePolicy",
    meth: HttpMethod.HttpPost, host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.DeletePolicy",
    validator: validate_DeletePolicy_606212, base: "/", url: url_DeletePolicy_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateAdminAccount_606226 = ref object of OpenApiRestCall_605589
proc url_DisassociateAdminAccount_606228(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateAdminAccount_606227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the account that has been set as the AWS Firewall Manager administrator account. To set a different account as the administrator account, you must submit an <code>AssociateAdminAccount</code> request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AWSFMS_20180101.DisassociateAdminAccount"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_DisassociateAdminAccount_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the account that has been set as the AWS Firewall Manager administrator account. To set a different account as the administrator account, you must submit an <code>AssociateAdminAccount</code> request.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_DisassociateAdminAccount_606226; body: JsonNode): Recallable =
  ## disassociateAdminAccount
  ## Disassociates the account that has been set as the AWS Firewall Manager administrator account. To set a different account as the administrator account, you must submit an <code>AssociateAdminAccount</code> request.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var disassociateAdminAccount* = Call_DisassociateAdminAccount_606226(
    name: "disassociateAdminAccount", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.DisassociateAdminAccount",
    validator: validate_DisassociateAdminAccount_606227, base: "/",
    url: url_DisassociateAdminAccount_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAdminAccount_606241 = ref object of OpenApiRestCall_605589
proc url_GetAdminAccount_606243(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAdminAccount_606242(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns the AWS Organizations master account that is associated with AWS Firewall Manager as the AWS Firewall Manager administrator.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "AWSFMS_20180101.GetAdminAccount"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_GetAdminAccount_606241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the AWS Organizations master account that is associated with AWS Firewall Manager as the AWS Firewall Manager administrator.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_GetAdminAccount_606241; body: JsonNode): Recallable =
  ## getAdminAccount
  ## Returns the AWS Organizations master account that is associated with AWS Firewall Manager as the AWS Firewall Manager administrator.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var getAdminAccount* = Call_GetAdminAccount_606241(name: "getAdminAccount",
    meth: HttpMethod.HttpPost, host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.GetAdminAccount",
    validator: validate_GetAdminAccount_606242, base: "/", url: url_GetAdminAccount_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceDetail_606256 = ref object of OpenApiRestCall_605589
proc url_GetComplianceDetail_606258(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceDetail_606257(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns detailed compliance information about the specified member account. Details include resources that are in and out of compliance with the specified policy. Resources are considered noncompliant for AWS WAF and Shield Advanced policies if the specified policy has not been applied to them. Resources are considered noncompliant for security group policies if they are in scope of the policy, they violate one or more of the policy rules, and remediation is disabled or not possible. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AWSFMS_20180101.GetComplianceDetail"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_GetComplianceDetail_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed compliance information about the specified member account. Details include resources that are in and out of compliance with the specified policy. Resources are considered noncompliant for AWS WAF and Shield Advanced policies if the specified policy has not been applied to them. Resources are considered noncompliant for security group policies if they are in scope of the policy, they violate one or more of the policy rules, and remediation is disabled or not possible. 
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_GetComplianceDetail_606256; body: JsonNode): Recallable =
  ## getComplianceDetail
  ## Returns detailed compliance information about the specified member account. Details include resources that are in and out of compliance with the specified policy. Resources are considered noncompliant for AWS WAF and Shield Advanced policies if the specified policy has not been applied to them. Resources are considered noncompliant for security group policies if they are in scope of the policy, they violate one or more of the policy rules, and remediation is disabled or not possible. 
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var getComplianceDetail* = Call_GetComplianceDetail_606256(
    name: "getComplianceDetail", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.GetComplianceDetail",
    validator: validate_GetComplianceDetail_606257, base: "/",
    url: url_GetComplianceDetail_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNotificationChannel_606271 = ref object of OpenApiRestCall_605589
proc url_GetNotificationChannel_606273(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNotificationChannel_606272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Information about the Amazon Simple Notification Service (SNS) topic that is used to record AWS Firewall Manager SNS logs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AWSFMS_20180101.GetNotificationChannel"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_GetNotificationChannel_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Information about the Amazon Simple Notification Service (SNS) topic that is used to record AWS Firewall Manager SNS logs.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_GetNotificationChannel_606271; body: JsonNode): Recallable =
  ## getNotificationChannel
  ## Information about the Amazon Simple Notification Service (SNS) topic that is used to record AWS Firewall Manager SNS logs.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var getNotificationChannel* = Call_GetNotificationChannel_606271(
    name: "getNotificationChannel", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.GetNotificationChannel",
    validator: validate_GetNotificationChannel_606272, base: "/",
    url: url_GetNotificationChannel_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_606286 = ref object of OpenApiRestCall_605589
proc url_GetPolicy_606288(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPolicy_606287(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the specified AWS Firewall Manager policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AWSFMS_20180101.GetPolicy"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_GetPolicy_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified AWS Firewall Manager policy.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_GetPolicy_606286; body: JsonNode): Recallable =
  ## getPolicy
  ## Returns information about the specified AWS Firewall Manager policy.
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var getPolicy* = Call_GetPolicy_606286(name: "getPolicy", meth: HttpMethod.HttpPost,
                                    host: "fms.amazonaws.com", route: "/#X-Amz-Target=AWSFMS_20180101.GetPolicy",
                                    validator: validate_GetPolicy_606287,
                                    base: "/", url: url_GetPolicy_606288,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProtectionStatus_606301 = ref object of OpenApiRestCall_605589
proc url_GetProtectionStatus_606303(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProtectionStatus_606302(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## If you created a Shield Advanced policy, returns policy-level attack summary information in the event of a potential DDoS attack. Other policy types are currently unsupported.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "AWSFMS_20180101.GetProtectionStatus"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_GetProtectionStatus_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If you created a Shield Advanced policy, returns policy-level attack summary information in the event of a potential DDoS attack. Other policy types are currently unsupported.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_GetProtectionStatus_606301; body: JsonNode): Recallable =
  ## getProtectionStatus
  ## If you created a Shield Advanced policy, returns policy-level attack summary information in the event of a potential DDoS attack. Other policy types are currently unsupported.
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var getProtectionStatus* = Call_GetProtectionStatus_606301(
    name: "getProtectionStatus", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.GetProtectionStatus",
    validator: validate_GetProtectionStatus_606302, base: "/",
    url: url_GetProtectionStatus_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceStatus_606316 = ref object of OpenApiRestCall_605589
proc url_ListComplianceStatus_606318(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComplianceStatus_606317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>PolicyComplianceStatus</code> objects in the response. Use <code>PolicyComplianceStatus</code> to get a summary of which member accounts are protected by the specified policy. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606319 = query.getOrDefault("MaxResults")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "MaxResults", valid_606319
  var valid_606320 = query.getOrDefault("NextToken")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "NextToken", valid_606320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606321 = header.getOrDefault("X-Amz-Target")
  valid_606321 = validateParameter(valid_606321, JString, required = true, default = newJString(
      "AWSFMS_20180101.ListComplianceStatus"))
  if valid_606321 != nil:
    section.add "X-Amz-Target", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Signature")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Signature", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Content-Sha256", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Date")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Date", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Credential")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Credential", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Security-Token")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Security-Token", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Algorithm")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Algorithm", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-SignedHeaders", valid_606328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606330: Call_ListComplianceStatus_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>PolicyComplianceStatus</code> objects in the response. Use <code>PolicyComplianceStatus</code> to get a summary of which member accounts are protected by the specified policy. 
  ## 
  let valid = call_606330.validator(path, query, header, formData, body)
  let scheme = call_606330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606330.url(scheme.get, call_606330.host, call_606330.base,
                         call_606330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606330, url, valid)

proc call*(call_606331: Call_ListComplianceStatus_606316; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listComplianceStatus
  ## Returns an array of <code>PolicyComplianceStatus</code> objects in the response. Use <code>PolicyComplianceStatus</code> to get a summary of which member accounts are protected by the specified policy. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606332 = newJObject()
  var body_606333 = newJObject()
  add(query_606332, "MaxResults", newJString(MaxResults))
  add(query_606332, "NextToken", newJString(NextToken))
  if body != nil:
    body_606333 = body
  result = call_606331.call(nil, query_606332, nil, nil, body_606333)

var listComplianceStatus* = Call_ListComplianceStatus_606316(
    name: "listComplianceStatus", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.ListComplianceStatus",
    validator: validate_ListComplianceStatus_606317, base: "/",
    url: url_ListComplianceStatus_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMemberAccounts_606335 = ref object of OpenApiRestCall_605589
proc url_ListMemberAccounts_606337(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMemberAccounts_606336(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a <code>MemberAccounts</code> object that lists the member accounts in the administrator's AWS organization.</p> <p>The <code>ListMemberAccounts</code> must be submitted by the account that is set as the AWS Firewall Manager administrator.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606338 = query.getOrDefault("MaxResults")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "MaxResults", valid_606338
  var valid_606339 = query.getOrDefault("NextToken")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "NextToken", valid_606339
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606340 = header.getOrDefault("X-Amz-Target")
  valid_606340 = validateParameter(valid_606340, JString, required = true, default = newJString(
      "AWSFMS_20180101.ListMemberAccounts"))
  if valid_606340 != nil:
    section.add "X-Amz-Target", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Signature")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Signature", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Content-Sha256", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Date")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Date", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Credential")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Credential", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Security-Token")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Security-Token", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Algorithm")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Algorithm", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-SignedHeaders", valid_606347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606349: Call_ListMemberAccounts_606335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a <code>MemberAccounts</code> object that lists the member accounts in the administrator's AWS organization.</p> <p>The <code>ListMemberAccounts</code> must be submitted by the account that is set as the AWS Firewall Manager administrator.</p>
  ## 
  let valid = call_606349.validator(path, query, header, formData, body)
  let scheme = call_606349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606349.url(scheme.get, call_606349.host, call_606349.base,
                         call_606349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606349, url, valid)

proc call*(call_606350: Call_ListMemberAccounts_606335; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMemberAccounts
  ## <p>Returns a <code>MemberAccounts</code> object that lists the member accounts in the administrator's AWS organization.</p> <p>The <code>ListMemberAccounts</code> must be submitted by the account that is set as the AWS Firewall Manager administrator.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606351 = newJObject()
  var body_606352 = newJObject()
  add(query_606351, "MaxResults", newJString(MaxResults))
  add(query_606351, "NextToken", newJString(NextToken))
  if body != nil:
    body_606352 = body
  result = call_606350.call(nil, query_606351, nil, nil, body_606352)

var listMemberAccounts* = Call_ListMemberAccounts_606335(
    name: "listMemberAccounts", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.ListMemberAccounts",
    validator: validate_ListMemberAccounts_606336, base: "/",
    url: url_ListMemberAccounts_606337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicies_606353 = ref object of OpenApiRestCall_605589
proc url_ListPolicies_606355(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPolicies_606354(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>PolicySummary</code> objects in the response.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606356 = query.getOrDefault("MaxResults")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "MaxResults", valid_606356
  var valid_606357 = query.getOrDefault("NextToken")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "NextToken", valid_606357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606358 = header.getOrDefault("X-Amz-Target")
  valid_606358 = validateParameter(valid_606358, JString, required = true, default = newJString(
      "AWSFMS_20180101.ListPolicies"))
  if valid_606358 != nil:
    section.add "X-Amz-Target", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Signature")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Signature", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Content-Sha256", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Date")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Date", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Credential")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Credential", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Security-Token")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Security-Token", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Algorithm")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Algorithm", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-SignedHeaders", valid_606365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606367: Call_ListPolicies_606353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>PolicySummary</code> objects in the response.
  ## 
  let valid = call_606367.validator(path, query, header, formData, body)
  let scheme = call_606367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606367.url(scheme.get, call_606367.host, call_606367.base,
                         call_606367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606367, url, valid)

proc call*(call_606368: Call_ListPolicies_606353; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicies
  ## Returns an array of <code>PolicySummary</code> objects in the response.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606369 = newJObject()
  var body_606370 = newJObject()
  add(query_606369, "MaxResults", newJString(MaxResults))
  add(query_606369, "NextToken", newJString(NextToken))
  if body != nil:
    body_606370 = body
  result = call_606368.call(nil, query_606369, nil, nil, body_606370)

var listPolicies* = Call_ListPolicies_606353(name: "listPolicies",
    meth: HttpMethod.HttpPost, host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.ListPolicies",
    validator: validate_ListPolicies_606354, base: "/", url: url_ListPolicies_606355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606371 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606373(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_606372(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the list of tags for the specified AWS resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606374 = header.getOrDefault("X-Amz-Target")
  valid_606374 = validateParameter(valid_606374, JString, required = true, default = newJString(
      "AWSFMS_20180101.ListTagsForResource"))
  if valid_606374 != nil:
    section.add "X-Amz-Target", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Signature")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Signature", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Content-Sha256", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Date")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Date", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Credential")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Credential", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Security-Token")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Security-Token", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Algorithm")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Algorithm", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-SignedHeaders", valid_606381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606383: Call_ListTagsForResource_606371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of tags for the specified AWS resource. 
  ## 
  let valid = call_606383.validator(path, query, header, formData, body)
  let scheme = call_606383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606383.url(scheme.get, call_606383.host, call_606383.base,
                         call_606383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606383, url, valid)

proc call*(call_606384: Call_ListTagsForResource_606371; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Retrieves the list of tags for the specified AWS resource. 
  ##   body: JObject (required)
  var body_606385 = newJObject()
  if body != nil:
    body_606385 = body
  result = call_606384.call(nil, nil, nil, nil, body_606385)

var listTagsForResource* = Call_ListTagsForResource_606371(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.ListTagsForResource",
    validator: validate_ListTagsForResource_606372, base: "/",
    url: url_ListTagsForResource_606373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutNotificationChannel_606386 = ref object of OpenApiRestCall_605589
proc url_PutNotificationChannel_606388(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutNotificationChannel_606387(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Designates the IAM role and Amazon Simple Notification Service (SNS) topic that AWS Firewall Manager uses to record SNS logs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606389 = header.getOrDefault("X-Amz-Target")
  valid_606389 = validateParameter(valid_606389, JString, required = true, default = newJString(
      "AWSFMS_20180101.PutNotificationChannel"))
  if valid_606389 != nil:
    section.add "X-Amz-Target", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Signature")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Signature", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Content-Sha256", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Date")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Date", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Credential")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Credential", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Security-Token")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Security-Token", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Algorithm")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Algorithm", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-SignedHeaders", valid_606396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606398: Call_PutNotificationChannel_606386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Designates the IAM role and Amazon Simple Notification Service (SNS) topic that AWS Firewall Manager uses to record SNS logs.
  ## 
  let valid = call_606398.validator(path, query, header, formData, body)
  let scheme = call_606398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606398.url(scheme.get, call_606398.host, call_606398.base,
                         call_606398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606398, url, valid)

proc call*(call_606399: Call_PutNotificationChannel_606386; body: JsonNode): Recallable =
  ## putNotificationChannel
  ## Designates the IAM role and Amazon Simple Notification Service (SNS) topic that AWS Firewall Manager uses to record SNS logs.
  ##   body: JObject (required)
  var body_606400 = newJObject()
  if body != nil:
    body_606400 = body
  result = call_606399.call(nil, nil, nil, nil, body_606400)

var putNotificationChannel* = Call_PutNotificationChannel_606386(
    name: "putNotificationChannel", meth: HttpMethod.HttpPost,
    host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.PutNotificationChannel",
    validator: validate_PutNotificationChannel_606387, base: "/",
    url: url_PutNotificationChannel_606388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPolicy_606401 = ref object of OpenApiRestCall_605589
proc url_PutPolicy_606403(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPolicy_606402(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an AWS Firewall Manager policy.</p> <p>Firewall Manager provides the following types of policies: </p> <ul> <li> <p>A Shield Advanced policy, which applies Shield Advanced protection to specified accounts and resources</p> </li> <li> <p>An AWS WAF policy, which contains a rule group and defines which resources are to be protected by that rule group</p> </li> <li> <p>A security group policy, which manages VPC security groups across your AWS organization. </p> </li> </ul> <p>Each policy is specific to one of the three types. If you want to enforce more than one policy type across accounts, you can create multiple policies. You can create multiple policies for each type.</p> <p>You must be subscribed to Shield Advanced to create a Shield Advanced policy. For more information about subscribing to Shield Advanced, see <a href="https://docs.aws.amazon.com/waf/latest/DDOSAPIReference/API_CreateSubscription.html">CreateSubscription</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606404 = header.getOrDefault("X-Amz-Target")
  valid_606404 = validateParameter(valid_606404, JString, required = true, default = newJString(
      "AWSFMS_20180101.PutPolicy"))
  if valid_606404 != nil:
    section.add "X-Amz-Target", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Signature")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Signature", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Content-Sha256", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Date")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Date", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Credential")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Credential", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Security-Token")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Security-Token", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Algorithm")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Algorithm", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-SignedHeaders", valid_606411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606413: Call_PutPolicy_606401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Firewall Manager policy.</p> <p>Firewall Manager provides the following types of policies: </p> <ul> <li> <p>A Shield Advanced policy, which applies Shield Advanced protection to specified accounts and resources</p> </li> <li> <p>An AWS WAF policy, which contains a rule group and defines which resources are to be protected by that rule group</p> </li> <li> <p>A security group policy, which manages VPC security groups across your AWS organization. </p> </li> </ul> <p>Each policy is specific to one of the three types. If you want to enforce more than one policy type across accounts, you can create multiple policies. You can create multiple policies for each type.</p> <p>You must be subscribed to Shield Advanced to create a Shield Advanced policy. For more information about subscribing to Shield Advanced, see <a href="https://docs.aws.amazon.com/waf/latest/DDOSAPIReference/API_CreateSubscription.html">CreateSubscription</a>.</p>
  ## 
  let valid = call_606413.validator(path, query, header, formData, body)
  let scheme = call_606413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606413.url(scheme.get, call_606413.host, call_606413.base,
                         call_606413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606413, url, valid)

proc call*(call_606414: Call_PutPolicy_606401; body: JsonNode): Recallable =
  ## putPolicy
  ## <p>Creates an AWS Firewall Manager policy.</p> <p>Firewall Manager provides the following types of policies: </p> <ul> <li> <p>A Shield Advanced policy, which applies Shield Advanced protection to specified accounts and resources</p> </li> <li> <p>An AWS WAF policy, which contains a rule group and defines which resources are to be protected by that rule group</p> </li> <li> <p>A security group policy, which manages VPC security groups across your AWS organization. </p> </li> </ul> <p>Each policy is specific to one of the three types. If you want to enforce more than one policy type across accounts, you can create multiple policies. You can create multiple policies for each type.</p> <p>You must be subscribed to Shield Advanced to create a Shield Advanced policy. For more information about subscribing to Shield Advanced, see <a href="https://docs.aws.amazon.com/waf/latest/DDOSAPIReference/API_CreateSubscription.html">CreateSubscription</a>.</p>
  ##   body: JObject (required)
  var body_606415 = newJObject()
  if body != nil:
    body_606415 = body
  result = call_606414.call(nil, nil, nil, nil, body_606415)

var putPolicy* = Call_PutPolicy_606401(name: "putPolicy", meth: HttpMethod.HttpPost,
                                    host: "fms.amazonaws.com", route: "/#X-Amz-Target=AWSFMS_20180101.PutPolicy",
                                    validator: validate_PutPolicy_606402,
                                    base: "/", url: url_PutPolicy_606403,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606416 = ref object of OpenApiRestCall_605589
proc url_TagResource_606418(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_606417(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to an AWS resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606419 = header.getOrDefault("X-Amz-Target")
  valid_606419 = validateParameter(valid_606419, JString, required = true, default = newJString(
      "AWSFMS_20180101.TagResource"))
  if valid_606419 != nil:
    section.add "X-Amz-Target", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Signature")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Signature", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Content-Sha256", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Date")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Date", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Credential")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Credential", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Security-Token")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Security-Token", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Algorithm")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Algorithm", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-SignedHeaders", valid_606426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606428: Call_TagResource_606416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to an AWS resource.
  ## 
  let valid = call_606428.validator(path, query, header, formData, body)
  let scheme = call_606428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606428.url(scheme.get, call_606428.host, call_606428.base,
                         call_606428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606428, url, valid)

proc call*(call_606429: Call_TagResource_606416; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to an AWS resource.
  ##   body: JObject (required)
  var body_606430 = newJObject()
  if body != nil:
    body_606430 = body
  result = call_606429.call(nil, nil, nil, nil, body_606430)

var tagResource* = Call_TagResource_606416(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "fms.amazonaws.com", route: "/#X-Amz-Target=AWSFMS_20180101.TagResource",
                                        validator: validate_TagResource_606417,
                                        base: "/", url: url_TagResource_606418,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606431 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606433(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_606432(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from an AWS resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606434 = header.getOrDefault("X-Amz-Target")
  valid_606434 = validateParameter(valid_606434, JString, required = true, default = newJString(
      "AWSFMS_20180101.UntagResource"))
  if valid_606434 != nil:
    section.add "X-Amz-Target", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Signature")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Signature", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Content-Sha256", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Date")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Date", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Credential")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Credential", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Security-Token")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Security-Token", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Algorithm")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Algorithm", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-SignedHeaders", valid_606441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606443: Call_UntagResource_606431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from an AWS resource.
  ## 
  let valid = call_606443.validator(path, query, header, formData, body)
  let scheme = call_606443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606443.url(scheme.get, call_606443.host, call_606443.base,
                         call_606443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606443, url, valid)

proc call*(call_606444: Call_UntagResource_606431; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from an AWS resource.
  ##   body: JObject (required)
  var body_606445 = newJObject()
  if body != nil:
    body_606445 = body
  result = call_606444.call(nil, nil, nil, nil, body_606445)

var untagResource* = Call_UntagResource_606431(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "fms.amazonaws.com",
    route: "/#X-Amz-Target=AWSFMS_20180101.UntagResource",
    validator: validate_UntagResource_606432, base: "/", url: url_UntagResource_606433,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

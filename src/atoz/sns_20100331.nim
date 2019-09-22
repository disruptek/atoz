
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Notification Service
## version: 2010-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Simple Notification Service</fullname> <p>Amazon Simple Notification Service (Amazon SNS) is a web service that enables you to build distributed web-enabled applications. Applications can use Amazon SNS to easily push real-time notification messages to interested subscribers over multiple delivery protocols. For more information about this product see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. For detailed information about Amazon SNS features and their associated API calls, see the <a href="https://docs.aws.amazon.com/sns/latest/dg/">Amazon SNS Developer Guide</a>. </p> <p>We also provide SDKs that enable you to access Amazon SNS from your preferred programming language. The SDKs contain functionality that automatically takes care of tasks such as: cryptographically signing your service requests, retrying requests, and handling error responses. For a list of available SDKs, go to <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sns/
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
              path: JsonNode): string

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "sns.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sns.us-west-2.amazonaws.com",
                           "eu-west-2": "sns.eu-west-2.amazonaws.com", "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sns.eu-central-1.amazonaws.com",
                           "us-east-2": "sns.us-east-2.amazonaws.com",
                           "us-east-1": "sns.us-east-1.amazonaws.com", "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sns.ap-south-1.amazonaws.com",
                           "eu-north-1": "sns.eu-north-1.amazonaws.com", "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sns.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sns.eu-west-3.amazonaws.com",
                           "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sns.sa-east-1.amazonaws.com",
                           "eu-west-1": "sns.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sns.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
      "us-west-2": "sns.us-west-2.amazonaws.com",
      "eu-west-2": "sns.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sns.eu-central-1.amazonaws.com",
      "us-east-2": "sns.us-east-2.amazonaws.com",
      "us-east-1": "sns.us-east-1.amazonaws.com",
      "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sns.ap-south-1.amazonaws.com",
      "eu-north-1": "sns.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
      "us-west-1": "sns.us-west-1.amazonaws.com",
      "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sns.eu-west-3.amazonaws.com",
      "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sns.sa-east-1.amazonaws.com",
      "eu-west-1": "sns.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sns"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_603044 = ref object of OpenApiRestCall_602433
proc url_PostAddPermission_603046(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddPermission_603045(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603047 = query.getOrDefault("Action")
  valid_603047 = validateParameter(valid_603047, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_603047 != nil:
    section.add "Action", valid_603047
  var valid_603048 = query.getOrDefault("Version")
  valid_603048 = validateParameter(valid_603048, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603048 != nil:
    section.add "Version", valid_603048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603049 = header.getOrDefault("X-Amz-Date")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Date", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Security-Token")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Security-Token", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Content-Sha256", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Algorithm")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Algorithm", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Signature")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Signature", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-SignedHeaders", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Credential")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Credential", valid_603055
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603056 = formData.getOrDefault("TopicArn")
  valid_603056 = validateParameter(valid_603056, JString, required = true,
                                 default = nil)
  if valid_603056 != nil:
    section.add "TopicArn", valid_603056
  var valid_603057 = formData.getOrDefault("AWSAccountId")
  valid_603057 = validateParameter(valid_603057, JArray, required = true, default = nil)
  if valid_603057 != nil:
    section.add "AWSAccountId", valid_603057
  var valid_603058 = formData.getOrDefault("Label")
  valid_603058 = validateParameter(valid_603058, JString, required = true,
                                 default = nil)
  if valid_603058 != nil:
    section.add "Label", valid_603058
  var valid_603059 = formData.getOrDefault("ActionName")
  valid_603059 = validateParameter(valid_603059, JArray, required = true, default = nil)
  if valid_603059 != nil:
    section.add "ActionName", valid_603059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603060: Call_PostAddPermission_603044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_603060.validator(path, query, header, formData, body)
  let scheme = call_603060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603060.url(scheme.get, call_603060.host, call_603060.base,
                         call_603060.route, valid.getOrDefault("path"))
  result = hook(call_603060, url, valid)

proc call*(call_603061: Call_PostAddPermission_603044; TopicArn: string;
          AWSAccountId: JsonNode; Label: string; ActionName: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## postAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   Action: string (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Version: string (required)
  var query_603062 = newJObject()
  var formData_603063 = newJObject()
  add(formData_603063, "TopicArn", newJString(TopicArn))
  if AWSAccountId != nil:
    formData_603063.add "AWSAccountId", AWSAccountId
  add(formData_603063, "Label", newJString(Label))
  add(query_603062, "Action", newJString(Action))
  if ActionName != nil:
    formData_603063.add "ActionName", ActionName
  add(query_603062, "Version", newJString(Version))
  result = call_603061.call(nil, query_603062, nil, formData_603063, nil)

var postAddPermission* = Call_PostAddPermission_603044(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_603045,
    base: "/", url: url_PostAddPermission_603046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_602770 = ref object of OpenApiRestCall_602433
proc url_GetAddPermission_602772(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddPermission_602771(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ActionName` field"
  var valid_602884 = query.getOrDefault("ActionName")
  valid_602884 = validateParameter(valid_602884, JArray, required = true, default = nil)
  if valid_602884 != nil:
    section.add "ActionName", valid_602884
  var valid_602898 = query.getOrDefault("Action")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_602898 != nil:
    section.add "Action", valid_602898
  var valid_602899 = query.getOrDefault("TopicArn")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = nil)
  if valid_602899 != nil:
    section.add "TopicArn", valid_602899
  var valid_602900 = query.getOrDefault("Version")
  valid_602900 = validateParameter(valid_602900, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602900 != nil:
    section.add "Version", valid_602900
  var valid_602901 = query.getOrDefault("Label")
  valid_602901 = validateParameter(valid_602901, JString, required = true,
                                 default = nil)
  if valid_602901 != nil:
    section.add "Label", valid_602901
  var valid_602902 = query.getOrDefault("AWSAccountId")
  valid_602902 = validateParameter(valid_602902, JArray, required = true, default = nil)
  if valid_602902 != nil:
    section.add "AWSAccountId", valid_602902
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602903 = header.getOrDefault("X-Amz-Date")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Date", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Security-Token")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Security-Token", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Content-Sha256", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Algorithm")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Algorithm", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Signature")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Signature", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-SignedHeaders", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Credential")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Credential", valid_602909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602932: Call_GetAddPermission_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_602932.validator(path, query, header, formData, body)
  let scheme = call_602932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602932.url(scheme.get, call_602932.host, call_602932.base,
                         call_602932.route, valid.getOrDefault("path"))
  result = hook(call_602932, url, valid)

proc call*(call_603003: Call_GetAddPermission_602770; ActionName: JsonNode;
          TopicArn: string; Label: string; AWSAccountId: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## getAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  var query_603004 = newJObject()
  if ActionName != nil:
    query_603004.add "ActionName", ActionName
  add(query_603004, "Action", newJString(Action))
  add(query_603004, "TopicArn", newJString(TopicArn))
  add(query_603004, "Version", newJString(Version))
  add(query_603004, "Label", newJString(Label))
  if AWSAccountId != nil:
    query_603004.add "AWSAccountId", AWSAccountId
  result = call_603003.call(nil, query_603004, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_602770(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_602771,
    base: "/", url: url_GetAddPermission_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_603080 = ref object of OpenApiRestCall_602433
proc url_PostCheckIfPhoneNumberIsOptedOut_603082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_603081(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603083 = query.getOrDefault("Action")
  valid_603083 = validateParameter(valid_603083, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_603083 != nil:
    section.add "Action", valid_603083
  var valid_603084 = query.getOrDefault("Version")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603084 != nil:
    section.add "Version", valid_603084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603085 = header.getOrDefault("X-Amz-Date")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Date", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Security-Token")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Security-Token", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Content-Sha256", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Algorithm")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Algorithm", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Signature")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Signature", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-SignedHeaders", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Credential")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Credential", valid_603091
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_603092 = formData.getOrDefault("phoneNumber")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = nil)
  if valid_603092 != nil:
    section.add "phoneNumber", valid_603092
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603093: Call_PostCheckIfPhoneNumberIsOptedOut_603080;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_603093.validator(path, query, header, formData, body)
  let scheme = call_603093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603093.url(scheme.get, call_603093.host, call_603093.base,
                         call_603093.route, valid.getOrDefault("path"))
  result = hook(call_603093, url, valid)

proc call*(call_603094: Call_PostCheckIfPhoneNumberIsOptedOut_603080;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Version: string (required)
  var query_603095 = newJObject()
  var formData_603096 = newJObject()
  add(query_603095, "Action", newJString(Action))
  add(formData_603096, "phoneNumber", newJString(phoneNumber))
  add(query_603095, "Version", newJString(Version))
  result = call_603094.call(nil, query_603095, nil, formData_603096, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_603080(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_603081, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_603082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_603064 = ref object of OpenApiRestCall_602433
proc url_GetCheckIfPhoneNumberIsOptedOut_603066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_603065(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_603067 = query.getOrDefault("phoneNumber")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = nil)
  if valid_603067 != nil:
    section.add "phoneNumber", valid_603067
  var valid_603068 = query.getOrDefault("Action")
  valid_603068 = validateParameter(valid_603068, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_603068 != nil:
    section.add "Action", valid_603068
  var valid_603069 = query.getOrDefault("Version")
  valid_603069 = validateParameter(valid_603069, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603069 != nil:
    section.add "Version", valid_603069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603070 = header.getOrDefault("X-Amz-Date")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Date", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Security-Token")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Security-Token", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Content-Sha256", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Algorithm")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Algorithm", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Signature")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Signature", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-SignedHeaders", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Credential")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Credential", valid_603076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_GetCheckIfPhoneNumberIsOptedOut_603064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"))
  result = hook(call_603077, url, valid)

proc call*(call_603078: Call_GetCheckIfPhoneNumberIsOptedOut_603064;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603079 = newJObject()
  add(query_603079, "phoneNumber", newJString(phoneNumber))
  add(query_603079, "Action", newJString(Action))
  add(query_603079, "Version", newJString(Version))
  result = call_603078.call(nil, query_603079, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_603064(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_603065, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_603066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_603115 = ref object of OpenApiRestCall_602433
proc url_PostConfirmSubscription_603117(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostConfirmSubscription_603116(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603118 = query.getOrDefault("Action")
  valid_603118 = validateParameter(valid_603118, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_603118 != nil:
    section.add "Action", valid_603118
  var valid_603119 = query.getOrDefault("Version")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603119 != nil:
    section.add "Version", valid_603119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Content-Sha256", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Algorithm")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Algorithm", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Signature")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Signature", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-SignedHeaders", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Credential")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Credential", valid_603126
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603127 = formData.getOrDefault("TopicArn")
  valid_603127 = validateParameter(valid_603127, JString, required = true,
                                 default = nil)
  if valid_603127 != nil:
    section.add "TopicArn", valid_603127
  var valid_603128 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_603128
  var valid_603129 = formData.getOrDefault("Token")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = nil)
  if valid_603129 != nil:
    section.add "Token", valid_603129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603130: Call_PostConfirmSubscription_603115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_603130.validator(path, query, header, formData, body)
  let scheme = call_603130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603130.url(scheme.get, call_603130.host, call_603130.base,
                         call_603130.route, valid.getOrDefault("path"))
  result = hook(call_603130, url, valid)

proc call*(call_603131: Call_PostConfirmSubscription_603115; TopicArn: string;
          Token: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## postConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  var query_603132 = newJObject()
  var formData_603133 = newJObject()
  add(formData_603133, "TopicArn", newJString(TopicArn))
  add(formData_603133, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_603132, "Action", newJString(Action))
  add(query_603132, "Version", newJString(Version))
  add(formData_603133, "Token", newJString(Token))
  result = call_603131.call(nil, query_603132, nil, formData_603133, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_603115(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_603116, base: "/",
    url: url_PostConfirmSubscription_603117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_603097 = ref object of OpenApiRestCall_602433
proc url_GetConfirmSubscription_603099(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConfirmSubscription_603098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_603100 = query.getOrDefault("Token")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = nil)
  if valid_603100 != nil:
    section.add "Token", valid_603100
  var valid_603101 = query.getOrDefault("Action")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_603101 != nil:
    section.add "Action", valid_603101
  var valid_603102 = query.getOrDefault("TopicArn")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = nil)
  if valid_603102 != nil:
    section.add "TopicArn", valid_603102
  var valid_603103 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_603103
  var valid_603104 = query.getOrDefault("Version")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603104 != nil:
    section.add "Version", valid_603104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Content-Sha256", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Algorithm")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Algorithm", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Signature")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Signature", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-SignedHeaders", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Credential")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Credential", valid_603111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603112: Call_GetConfirmSubscription_603097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_603112.validator(path, query, header, formData, body)
  let scheme = call_603112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603112.url(scheme.get, call_603112.host, call_603112.base,
                         call_603112.route, valid.getOrDefault("path"))
  result = hook(call_603112, url, valid)

proc call*(call_603113: Call_GetConfirmSubscription_603097; Token: string;
          TopicArn: string; Action: string = "ConfirmSubscription";
          AuthenticateOnUnsubscribe: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Version: string (required)
  var query_603114 = newJObject()
  add(query_603114, "Token", newJString(Token))
  add(query_603114, "Action", newJString(Action))
  add(query_603114, "TopicArn", newJString(TopicArn))
  add(query_603114, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_603114, "Version", newJString(Version))
  result = call_603113.call(nil, query_603114, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_603097(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_603098, base: "/",
    url: url_GetConfirmSubscription_603099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_603157 = ref object of OpenApiRestCall_602433
proc url_PostCreatePlatformApplication_603159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformApplication_603158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603160 = query.getOrDefault("Action")
  valid_603160 = validateParameter(valid_603160, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_603160 != nil:
    section.add "Action", valid_603160
  var valid_603161 = query.getOrDefault("Version")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603161 != nil:
    section.add "Version", valid_603161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Content-Sha256", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Algorithm")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Algorithm", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Signature")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Signature", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-SignedHeaders", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Credential")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Credential", valid_603168
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_603169 = formData.getOrDefault("Name")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = nil)
  if valid_603169 != nil:
    section.add "Name", valid_603169
  var valid_603170 = formData.getOrDefault("Attributes.0.value")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "Attributes.0.value", valid_603170
  var valid_603171 = formData.getOrDefault("Attributes.0.key")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "Attributes.0.key", valid_603171
  var valid_603172 = formData.getOrDefault("Attributes.1.key")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "Attributes.1.key", valid_603172
  var valid_603173 = formData.getOrDefault("Attributes.2.value")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "Attributes.2.value", valid_603173
  var valid_603174 = formData.getOrDefault("Platform")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "Platform", valid_603174
  var valid_603175 = formData.getOrDefault("Attributes.2.key")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Attributes.2.key", valid_603175
  var valid_603176 = formData.getOrDefault("Attributes.1.value")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "Attributes.1.value", valid_603176
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603177: Call_PostCreatePlatformApplication_603157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_603177.validator(path, query, header, formData, body)
  let scheme = call_603177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603177.url(scheme.get, call_603177.host, call_603177.base,
                         call_603177.route, valid.getOrDefault("path"))
  result = hook(call_603177, url, valid)

proc call*(call_603178: Call_PostCreatePlatformApplication_603157; Name: string;
          Platform: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformApplication";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_603179 = newJObject()
  var formData_603180 = newJObject()
  add(formData_603180, "Name", newJString(Name))
  add(formData_603180, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603180, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603180, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603179, "Action", newJString(Action))
  add(formData_603180, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603180, "Platform", newJString(Platform))
  add(formData_603180, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603179, "Version", newJString(Version))
  add(formData_603180, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603178.call(nil, query_603179, nil, formData_603180, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_603157(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_603158, base: "/",
    url: url_PostCreatePlatformApplication_603159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_603134 = ref object of OpenApiRestCall_602433
proc url_GetCreatePlatformApplication_603136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformApplication_603135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_603137 = query.getOrDefault("Attributes.2.key")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "Attributes.2.key", valid_603137
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_603138 = query.getOrDefault("Name")
  valid_603138 = validateParameter(valid_603138, JString, required = true,
                                 default = nil)
  if valid_603138 != nil:
    section.add "Name", valid_603138
  var valid_603139 = query.getOrDefault("Attributes.1.value")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "Attributes.1.value", valid_603139
  var valid_603140 = query.getOrDefault("Attributes.0.value")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "Attributes.0.value", valid_603140
  var valid_603141 = query.getOrDefault("Action")
  valid_603141 = validateParameter(valid_603141, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_603141 != nil:
    section.add "Action", valid_603141
  var valid_603142 = query.getOrDefault("Attributes.1.key")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "Attributes.1.key", valid_603142
  var valid_603143 = query.getOrDefault("Platform")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = nil)
  if valid_603143 != nil:
    section.add "Platform", valid_603143
  var valid_603144 = query.getOrDefault("Attributes.2.value")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "Attributes.2.value", valid_603144
  var valid_603145 = query.getOrDefault("Attributes.0.key")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "Attributes.0.key", valid_603145
  var valid_603146 = query.getOrDefault("Version")
  valid_603146 = validateParameter(valid_603146, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603146 != nil:
    section.add "Version", valid_603146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Content-Sha256", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Algorithm")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Algorithm", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Signature")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Signature", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-SignedHeaders", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Credential")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Credential", valid_603153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603154: Call_GetCreatePlatformApplication_603134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_603154.validator(path, query, header, formData, body)
  let scheme = call_603154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603154.url(scheme.get, call_603154.host, call_603154.base,
                         call_603154.route, valid.getOrDefault("path"))
  result = hook(call_603154, url, valid)

proc call*(call_603155: Call_GetCreatePlatformApplication_603134; Name: string;
          Platform: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "CreatePlatformApplication"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Attributes2Key: string
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_603156 = newJObject()
  add(query_603156, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603156, "Name", newJString(Name))
  add(query_603156, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603156, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603156, "Action", newJString(Action))
  add(query_603156, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603156, "Platform", newJString(Platform))
  add(query_603156, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603156, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603156, "Version", newJString(Version))
  result = call_603155.call(nil, query_603156, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_603134(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_603135, base: "/",
    url: url_GetCreatePlatformApplication_603136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_603205 = ref object of OpenApiRestCall_602433
proc url_PostCreatePlatformEndpoint_603207(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformEndpoint_603206(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603208 = query.getOrDefault("Action")
  valid_603208 = validateParameter(valid_603208, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_603208 != nil:
    section.add "Action", valid_603208
  var valid_603209 = query.getOrDefault("Version")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603209 != nil:
    section.add "Version", valid_603209
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Content-Sha256", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Algorithm")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Algorithm", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Signature")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Signature", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-SignedHeaders", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Credential")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Credential", valid_603216
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  section = newJObject()
  var valid_603217 = formData.getOrDefault("Attributes.0.value")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "Attributes.0.value", valid_603217
  var valid_603218 = formData.getOrDefault("Attributes.0.key")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "Attributes.0.key", valid_603218
  var valid_603219 = formData.getOrDefault("Attributes.1.key")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "Attributes.1.key", valid_603219
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603220 = formData.getOrDefault("PlatformApplicationArn")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = nil)
  if valid_603220 != nil:
    section.add "PlatformApplicationArn", valid_603220
  var valid_603221 = formData.getOrDefault("CustomUserData")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "CustomUserData", valid_603221
  var valid_603222 = formData.getOrDefault("Attributes.2.value")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "Attributes.2.value", valid_603222
  var valid_603223 = formData.getOrDefault("Attributes.2.key")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Attributes.2.key", valid_603223
  var valid_603224 = formData.getOrDefault("Attributes.1.value")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "Attributes.1.value", valid_603224
  var valid_603225 = formData.getOrDefault("Token")
  valid_603225 = validateParameter(valid_603225, JString, required = true,
                                 default = nil)
  if valid_603225 != nil:
    section.add "Token", valid_603225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_PostCreatePlatformEndpoint_603205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_PostCreatePlatformEndpoint_603205;
          PlatformApplicationArn: string; Token: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "CreatePlatformEndpoint";
          CustomUserData: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  var query_603228 = newJObject()
  var formData_603229 = newJObject()
  add(formData_603229, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603229, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603229, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603228, "Action", newJString(Action))
  add(formData_603229, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_603229, "CustomUserData", newJString(CustomUserData))
  add(formData_603229, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603229, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603228, "Version", newJString(Version))
  add(formData_603229, "Attributes.1.value", newJString(Attributes1Value))
  add(formData_603229, "Token", newJString(Token))
  result = call_603227.call(nil, query_603228, nil, formData_603229, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_603205(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_603206, base: "/",
    url: url_PostCreatePlatformEndpoint_603207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_603181 = ref object of OpenApiRestCall_602433
proc url_GetCreatePlatformEndpoint_603183(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformEndpoint_603182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.2.key: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  section = newJObject()
  var valid_603184 = query.getOrDefault("CustomUserData")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "CustomUserData", valid_603184
  var valid_603185 = query.getOrDefault("Attributes.2.key")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "Attributes.2.key", valid_603185
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_603186 = query.getOrDefault("Token")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = nil)
  if valid_603186 != nil:
    section.add "Token", valid_603186
  var valid_603187 = query.getOrDefault("Attributes.1.value")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "Attributes.1.value", valid_603187
  var valid_603188 = query.getOrDefault("Attributes.0.value")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "Attributes.0.value", valid_603188
  var valid_603189 = query.getOrDefault("Action")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_603189 != nil:
    section.add "Action", valid_603189
  var valid_603190 = query.getOrDefault("Attributes.1.key")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "Attributes.1.key", valid_603190
  var valid_603191 = query.getOrDefault("Attributes.2.value")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "Attributes.2.value", valid_603191
  var valid_603192 = query.getOrDefault("Attributes.0.key")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "Attributes.0.key", valid_603192
  var valid_603193 = query.getOrDefault("Version")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603193 != nil:
    section.add "Version", valid_603193
  var valid_603194 = query.getOrDefault("PlatformApplicationArn")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = nil)
  if valid_603194 != nil:
    section.add "PlatformApplicationArn", valid_603194
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Content-Sha256", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Algorithm")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Algorithm", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Signature")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Signature", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-SignedHeaders", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Credential")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Credential", valid_603201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603202: Call_GetCreatePlatformEndpoint_603181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_603202.validator(path, query, header, formData, body)
  let scheme = call_603202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603202.url(scheme.get, call_603202.host, call_603202.base,
                         call_603202.route, valid.getOrDefault("path"))
  result = hook(call_603202, url, valid)

proc call*(call_603203: Call_GetCreatePlatformEndpoint_603181; Token: string;
          PlatformApplicationArn: string; CustomUserData: string = "";
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "CreatePlatformEndpoint";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes2Key: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  var query_603204 = newJObject()
  add(query_603204, "CustomUserData", newJString(CustomUserData))
  add(query_603204, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603204, "Token", newJString(Token))
  add(query_603204, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603204, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603204, "Action", newJString(Action))
  add(query_603204, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603204, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603204, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603204, "Version", newJString(Version))
  add(query_603204, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603203.call(nil, query_603204, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_603181(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_603182, base: "/",
    url: url_GetCreatePlatformEndpoint_603183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_603253 = ref object of OpenApiRestCall_602433
proc url_PostCreateTopic_603255(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateTopic_603254(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603256 = query.getOrDefault("Action")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_603256 != nil:
    section.add "Action", valid_603256
  var valid_603257 = query.getOrDefault("Version")
  valid_603257 = validateParameter(valid_603257, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603257 != nil:
    section.add "Version", valid_603257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603258 = header.getOrDefault("X-Amz-Date")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Date", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Security-Token")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Security-Token", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Content-Sha256", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Algorithm")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Algorithm", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Signature")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Signature", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-SignedHeaders", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Credential")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Credential", valid_603264
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_603265 = formData.getOrDefault("Name")
  valid_603265 = validateParameter(valid_603265, JString, required = true,
                                 default = nil)
  if valid_603265 != nil:
    section.add "Name", valid_603265
  var valid_603266 = formData.getOrDefault("Attributes.0.value")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "Attributes.0.value", valid_603266
  var valid_603267 = formData.getOrDefault("Attributes.0.key")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "Attributes.0.key", valid_603267
  var valid_603268 = formData.getOrDefault("Tags")
  valid_603268 = validateParameter(valid_603268, JArray, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "Tags", valid_603268
  var valid_603269 = formData.getOrDefault("Attributes.1.key")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "Attributes.1.key", valid_603269
  var valid_603270 = formData.getOrDefault("Attributes.2.value")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "Attributes.2.value", valid_603270
  var valid_603271 = formData.getOrDefault("Attributes.2.key")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "Attributes.2.key", valid_603271
  var valid_603272 = formData.getOrDefault("Attributes.1.value")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "Attributes.1.value", valid_603272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603273: Call_PostCreateTopic_603253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_603273.validator(path, query, header, formData, body)
  let scheme = call_603273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603273.url(scheme.get, call_603273.host, call_603273.base,
                         call_603273.route, valid.getOrDefault("path"))
  result = hook(call_603273, url, valid)

proc call*(call_603274: Call_PostCreateTopic_603253; Name: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Tags: JsonNode = nil; Attributes1Key: string = "";
          Action: string = "CreateTopic"; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_603275 = newJObject()
  var formData_603276 = newJObject()
  add(formData_603276, "Name", newJString(Name))
  add(formData_603276, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603276, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    formData_603276.add "Tags", Tags
  add(formData_603276, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603275, "Action", newJString(Action))
  add(formData_603276, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603276, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603275, "Version", newJString(Version))
  add(formData_603276, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603274.call(nil, query_603275, nil, formData_603276, nil)

var postCreateTopic* = Call_PostCreateTopic_603253(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_603254,
    base: "/", url: url_PostCreateTopic_603255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_603230 = ref object of OpenApiRestCall_602433
proc url_GetCreateTopic_603232(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateTopic_603231(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes.1.value: JString
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_603233 = query.getOrDefault("Attributes.2.key")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "Attributes.2.key", valid_603233
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_603234 = query.getOrDefault("Name")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = nil)
  if valid_603234 != nil:
    section.add "Name", valid_603234
  var valid_603235 = query.getOrDefault("Attributes.1.value")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "Attributes.1.value", valid_603235
  var valid_603236 = query.getOrDefault("Tags")
  valid_603236 = validateParameter(valid_603236, JArray, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "Tags", valid_603236
  var valid_603237 = query.getOrDefault("Attributes.0.value")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "Attributes.0.value", valid_603237
  var valid_603238 = query.getOrDefault("Action")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_603238 != nil:
    section.add "Action", valid_603238
  var valid_603239 = query.getOrDefault("Attributes.1.key")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "Attributes.1.key", valid_603239
  var valid_603240 = query.getOrDefault("Attributes.2.value")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "Attributes.2.value", valid_603240
  var valid_603241 = query.getOrDefault("Attributes.0.key")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "Attributes.0.key", valid_603241
  var valid_603242 = query.getOrDefault("Version")
  valid_603242 = validateParameter(valid_603242, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603242 != nil:
    section.add "Version", valid_603242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603243 = header.getOrDefault("X-Amz-Date")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Date", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Security-Token")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Security-Token", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Content-Sha256", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Algorithm")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Algorithm", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Signature")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Signature", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-SignedHeaders", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Credential")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Credential", valid_603249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603250: Call_GetCreateTopic_603230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_603250.validator(path, query, header, formData, body)
  let scheme = call_603250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603250.url(scheme.get, call_603250.host, call_603250.base,
                         call_603250.route, valid.getOrDefault("path"))
  result = hook(call_603250, url, valid)

proc call*(call_603251: Call_GetCreateTopic_603230; Name: string;
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Tags: JsonNode = nil; Attributes0Value: string = "";
          Action: string = "CreateTopic"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes2Key: string
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes1Value: string
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_603252 = newJObject()
  add(query_603252, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603252, "Name", newJString(Name))
  add(query_603252, "Attributes.1.value", newJString(Attributes1Value))
  if Tags != nil:
    query_603252.add "Tags", Tags
  add(query_603252, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603252, "Action", newJString(Action))
  add(query_603252, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603252, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603252, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603252, "Version", newJString(Version))
  result = call_603251.call(nil, query_603252, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_603230(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_603231,
    base: "/", url: url_GetCreateTopic_603232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_603293 = ref object of OpenApiRestCall_602433
proc url_PostDeleteEndpoint_603295(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEndpoint_603294(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603296 = query.getOrDefault("Action")
  valid_603296 = validateParameter(valid_603296, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_603296 != nil:
    section.add "Action", valid_603296
  var valid_603297 = query.getOrDefault("Version")
  valid_603297 = validateParameter(valid_603297, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603297 != nil:
    section.add "Version", valid_603297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603298 = header.getOrDefault("X-Amz-Date")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Date", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Security-Token")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Security-Token", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Content-Sha256", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Signature", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-SignedHeaders", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_603305 = formData.getOrDefault("EndpointArn")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = nil)
  if valid_603305 != nil:
    section.add "EndpointArn", valid_603305
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603306: Call_PostDeleteEndpoint_603293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_603306.validator(path, query, header, formData, body)
  let scheme = call_603306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603306.url(scheme.get, call_603306.host, call_603306.base,
                         call_603306.route, valid.getOrDefault("path"))
  result = hook(call_603306, url, valid)

proc call*(call_603307: Call_PostDeleteEndpoint_603293; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_603308 = newJObject()
  var formData_603309 = newJObject()
  add(query_603308, "Action", newJString(Action))
  add(formData_603309, "EndpointArn", newJString(EndpointArn))
  add(query_603308, "Version", newJString(Version))
  result = call_603307.call(nil, query_603308, nil, formData_603309, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_603293(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_603294, base: "/",
    url: url_PostDeleteEndpoint_603295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_603277 = ref object of OpenApiRestCall_602433
proc url_GetDeleteEndpoint_603279(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEndpoint_603278(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_603280 = query.getOrDefault("EndpointArn")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = nil)
  if valid_603280 != nil:
    section.add "EndpointArn", valid_603280
  var valid_603281 = query.getOrDefault("Action")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_603281 != nil:
    section.add "Action", valid_603281
  var valid_603282 = query.getOrDefault("Version")
  valid_603282 = validateParameter(valid_603282, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603282 != nil:
    section.add "Version", valid_603282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603283 = header.getOrDefault("X-Amz-Date")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Date", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Security-Token")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Security-Token", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Content-Sha256", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Signature")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Signature", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603290: Call_GetDeleteEndpoint_603277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_603290.validator(path, query, header, formData, body)
  let scheme = call_603290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603290.url(scheme.get, call_603290.host, call_603290.base,
                         call_603290.route, valid.getOrDefault("path"))
  result = hook(call_603290, url, valid)

proc call*(call_603291: Call_GetDeleteEndpoint_603277; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603292 = newJObject()
  add(query_603292, "EndpointArn", newJString(EndpointArn))
  add(query_603292, "Action", newJString(Action))
  add(query_603292, "Version", newJString(Version))
  result = call_603291.call(nil, query_603292, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_603277(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_603278,
    base: "/", url: url_GetDeleteEndpoint_603279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_603326 = ref object of OpenApiRestCall_602433
proc url_PostDeletePlatformApplication_603328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeletePlatformApplication_603327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603329 = query.getOrDefault("Action")
  valid_603329 = validateParameter(valid_603329, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_603329 != nil:
    section.add "Action", valid_603329
  var valid_603330 = query.getOrDefault("Version")
  valid_603330 = validateParameter(valid_603330, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603330 != nil:
    section.add "Version", valid_603330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603331 = header.getOrDefault("X-Amz-Date")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Date", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Security-Token")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Security-Token", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603338 = formData.getOrDefault("PlatformApplicationArn")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = nil)
  if valid_603338 != nil:
    section.add "PlatformApplicationArn", valid_603338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_PostDeletePlatformApplication_603326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_PostDeletePlatformApplication_603326;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Version: string (required)
  var query_603341 = newJObject()
  var formData_603342 = newJObject()
  add(query_603341, "Action", newJString(Action))
  add(formData_603342, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_603341, "Version", newJString(Version))
  result = call_603340.call(nil, query_603341, nil, formData_603342, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_603326(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_603327, base: "/",
    url: url_PostDeletePlatformApplication_603328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_603310 = ref object of OpenApiRestCall_602433
proc url_GetDeletePlatformApplication_603312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeletePlatformApplication_603311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603313 = query.getOrDefault("Action")
  valid_603313 = validateParameter(valid_603313, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_603313 != nil:
    section.add "Action", valid_603313
  var valid_603314 = query.getOrDefault("Version")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603314 != nil:
    section.add "Version", valid_603314
  var valid_603315 = query.getOrDefault("PlatformApplicationArn")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = nil)
  if valid_603315 != nil:
    section.add "PlatformApplicationArn", valid_603315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603323: Call_GetDeletePlatformApplication_603310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603323.validator(path, query, header, formData, body)
  let scheme = call_603323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603323.url(scheme.get, call_603323.host, call_603323.base,
                         call_603323.route, valid.getOrDefault("path"))
  result = hook(call_603323, url, valid)

proc call*(call_603324: Call_GetDeletePlatformApplication_603310;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  var query_603325 = newJObject()
  add(query_603325, "Action", newJString(Action))
  add(query_603325, "Version", newJString(Version))
  add(query_603325, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603324.call(nil, query_603325, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_603310(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_603311, base: "/",
    url: url_GetDeletePlatformApplication_603312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_603359 = ref object of OpenApiRestCall_602433
proc url_PostDeleteTopic_603361(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteTopic_603360(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603362 = query.getOrDefault("Action")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_603362 != nil:
    section.add "Action", valid_603362
  var valid_603363 = query.getOrDefault("Version")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603363 != nil:
    section.add "Version", valid_603363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Algorithm")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Algorithm", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603371 = formData.getOrDefault("TopicArn")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "TopicArn", valid_603371
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603372: Call_PostDeleteTopic_603359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_603372.validator(path, query, header, formData, body)
  let scheme = call_603372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603372.url(scheme.get, call_603372.host, call_603372.base,
                         call_603372.route, valid.getOrDefault("path"))
  result = hook(call_603372, url, valid)

proc call*(call_603373: Call_PostDeleteTopic_603359; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603374 = newJObject()
  var formData_603375 = newJObject()
  add(formData_603375, "TopicArn", newJString(TopicArn))
  add(query_603374, "Action", newJString(Action))
  add(query_603374, "Version", newJString(Version))
  result = call_603373.call(nil, query_603374, nil, formData_603375, nil)

var postDeleteTopic* = Call_PostDeleteTopic_603359(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_603360,
    base: "/", url: url_PostDeleteTopic_603361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_603343 = ref object of OpenApiRestCall_602433
proc url_GetDeleteTopic_603345(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteTopic_603344(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603346 = query.getOrDefault("Action")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_603346 != nil:
    section.add "Action", valid_603346
  var valid_603347 = query.getOrDefault("TopicArn")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = nil)
  if valid_603347 != nil:
    section.add "TopicArn", valid_603347
  var valid_603348 = query.getOrDefault("Version")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603348 != nil:
    section.add "Version", valid_603348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Security-Token")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Security-Token", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Content-Sha256", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Algorithm")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Algorithm", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Signature")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Signature", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-SignedHeaders", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Credential")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Credential", valid_603355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603356: Call_GetDeleteTopic_603343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_603356.validator(path, query, header, formData, body)
  let scheme = call_603356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603356.url(scheme.get, call_603356.host, call_603356.base,
                         call_603356.route, valid.getOrDefault("path"))
  result = hook(call_603356, url, valid)

proc call*(call_603357: Call_GetDeleteTopic_603343; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: string (required)
  var query_603358 = newJObject()
  add(query_603358, "Action", newJString(Action))
  add(query_603358, "TopicArn", newJString(TopicArn))
  add(query_603358, "Version", newJString(Version))
  result = call_603357.call(nil, query_603358, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_603343(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_603344,
    base: "/", url: url_GetDeleteTopic_603345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_603392 = ref object of OpenApiRestCall_602433
proc url_PostGetEndpointAttributes_603394(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetEndpointAttributes_603393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603395 = query.getOrDefault("Action")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_603395 != nil:
    section.add "Action", valid_603395
  var valid_603396 = query.getOrDefault("Version")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603396 != nil:
    section.add "Version", valid_603396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603397 = header.getOrDefault("X-Amz-Date")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Date", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Security-Token")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Security-Token", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Content-Sha256", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Algorithm")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Algorithm", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Signature")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Signature", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-SignedHeaders", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Credential")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Credential", valid_603403
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_603404 = formData.getOrDefault("EndpointArn")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = nil)
  if valid_603404 != nil:
    section.add "EndpointArn", valid_603404
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603405: Call_PostGetEndpointAttributes_603392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603405.validator(path, query, header, formData, body)
  let scheme = call_603405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603405.url(scheme.get, call_603405.host, call_603405.base,
                         call_603405.route, valid.getOrDefault("path"))
  result = hook(call_603405, url, valid)

proc call*(call_603406: Call_PostGetEndpointAttributes_603392; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_603407 = newJObject()
  var formData_603408 = newJObject()
  add(query_603407, "Action", newJString(Action))
  add(formData_603408, "EndpointArn", newJString(EndpointArn))
  add(query_603407, "Version", newJString(Version))
  result = call_603406.call(nil, query_603407, nil, formData_603408, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_603392(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_603393, base: "/",
    url: url_PostGetEndpointAttributes_603394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_603376 = ref object of OpenApiRestCall_602433
proc url_GetGetEndpointAttributes_603378(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetEndpointAttributes_603377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_603379 = query.getOrDefault("EndpointArn")
  valid_603379 = validateParameter(valid_603379, JString, required = true,
                                 default = nil)
  if valid_603379 != nil:
    section.add "EndpointArn", valid_603379
  var valid_603380 = query.getOrDefault("Action")
  valid_603380 = validateParameter(valid_603380, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_603380 != nil:
    section.add "Action", valid_603380
  var valid_603381 = query.getOrDefault("Version")
  valid_603381 = validateParameter(valid_603381, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603381 != nil:
    section.add "Version", valid_603381
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603382 = header.getOrDefault("X-Amz-Date")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Date", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Security-Token")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Security-Token", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Content-Sha256", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Algorithm")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Algorithm", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Signature")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Signature", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-SignedHeaders", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Credential")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Credential", valid_603388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603389: Call_GetGetEndpointAttributes_603376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603389.validator(path, query, header, formData, body)
  let scheme = call_603389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603389.url(scheme.get, call_603389.host, call_603389.base,
                         call_603389.route, valid.getOrDefault("path"))
  result = hook(call_603389, url, valid)

proc call*(call_603390: Call_GetGetEndpointAttributes_603376; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603391 = newJObject()
  add(query_603391, "EndpointArn", newJString(EndpointArn))
  add(query_603391, "Action", newJString(Action))
  add(query_603391, "Version", newJString(Version))
  result = call_603390.call(nil, query_603391, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_603376(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_603377, base: "/",
    url: url_GetGetEndpointAttributes_603378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_603425 = ref object of OpenApiRestCall_602433
proc url_PostGetPlatformApplicationAttributes_603427(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetPlatformApplicationAttributes_603426(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603428 = query.getOrDefault("Action")
  valid_603428 = validateParameter(valid_603428, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_603428 != nil:
    section.add "Action", valid_603428
  var valid_603429 = query.getOrDefault("Version")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603429 != nil:
    section.add "Version", valid_603429
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603430 = header.getOrDefault("X-Amz-Date")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Date", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Security-Token")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Security-Token", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Content-Sha256", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Algorithm")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Algorithm", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Signature")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Signature", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-SignedHeaders", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Credential")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Credential", valid_603436
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603437 = formData.getOrDefault("PlatformApplicationArn")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = nil)
  if valid_603437 != nil:
    section.add "PlatformApplicationArn", valid_603437
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603438: Call_PostGetPlatformApplicationAttributes_603425;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603438.validator(path, query, header, formData, body)
  let scheme = call_603438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603438.url(scheme.get, call_603438.host, call_603438.base,
                         call_603438.route, valid.getOrDefault("path"))
  result = hook(call_603438, url, valid)

proc call*(call_603439: Call_PostGetPlatformApplicationAttributes_603425;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Version: string (required)
  var query_603440 = newJObject()
  var formData_603441 = newJObject()
  add(query_603440, "Action", newJString(Action))
  add(formData_603441, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_603440, "Version", newJString(Version))
  result = call_603439.call(nil, query_603440, nil, formData_603441, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_603425(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_603426, base: "/",
    url: url_PostGetPlatformApplicationAttributes_603427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_603409 = ref object of OpenApiRestCall_602433
proc url_GetGetPlatformApplicationAttributes_603411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetPlatformApplicationAttributes_603410(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603412 = query.getOrDefault("Action")
  valid_603412 = validateParameter(valid_603412, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_603412 != nil:
    section.add "Action", valid_603412
  var valid_603413 = query.getOrDefault("Version")
  valid_603413 = validateParameter(valid_603413, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603413 != nil:
    section.add "Version", valid_603413
  var valid_603414 = query.getOrDefault("PlatformApplicationArn")
  valid_603414 = validateParameter(valid_603414, JString, required = true,
                                 default = nil)
  if valid_603414 != nil:
    section.add "PlatformApplicationArn", valid_603414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603415 = header.getOrDefault("X-Amz-Date")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Date", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Security-Token")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Security-Token", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Content-Sha256", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Algorithm")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Algorithm", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Signature")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Signature", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-SignedHeaders", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Credential")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Credential", valid_603421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603422: Call_GetGetPlatformApplicationAttributes_603409;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603422.validator(path, query, header, formData, body)
  let scheme = call_603422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603422.url(scheme.get, call_603422.host, call_603422.base,
                         call_603422.route, valid.getOrDefault("path"))
  result = hook(call_603422, url, valid)

proc call*(call_603423: Call_GetGetPlatformApplicationAttributes_603409;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  var query_603424 = newJObject()
  add(query_603424, "Action", newJString(Action))
  add(query_603424, "Version", newJString(Version))
  add(query_603424, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603423.call(nil, query_603424, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_603409(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_603410, base: "/",
    url: url_GetGetPlatformApplicationAttributes_603411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_603458 = ref object of OpenApiRestCall_602433
proc url_PostGetSMSAttributes_603460(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetSMSAttributes_603459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603461 = query.getOrDefault("Action")
  valid_603461 = validateParameter(valid_603461, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_603461 != nil:
    section.add "Action", valid_603461
  var valid_603462 = query.getOrDefault("Version")
  valid_603462 = validateParameter(valid_603462, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603462 != nil:
    section.add "Version", valid_603462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603463 = header.getOrDefault("X-Amz-Date")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Date", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Security-Token")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Security-Token", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Content-Sha256", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Algorithm")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Algorithm", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Signature")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Signature", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-SignedHeaders", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Credential")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Credential", valid_603469
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_603470 = formData.getOrDefault("attributes")
  valid_603470 = validateParameter(valid_603470, JArray, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "attributes", valid_603470
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603471: Call_PostGetSMSAttributes_603458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_603471.validator(path, query, header, formData, body)
  let scheme = call_603471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603471.url(scheme.get, call_603471.host, call_603471.base,
                         call_603471.route, valid.getOrDefault("path"))
  result = hook(call_603471, url, valid)

proc call*(call_603472: Call_PostGetSMSAttributes_603458;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603473 = newJObject()
  var formData_603474 = newJObject()
  if attributes != nil:
    formData_603474.add "attributes", attributes
  add(query_603473, "Action", newJString(Action))
  add(query_603473, "Version", newJString(Version))
  result = call_603472.call(nil, query_603473, nil, formData_603474, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_603458(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_603459, base: "/",
    url: url_PostGetSMSAttributes_603460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_603442 = ref object of OpenApiRestCall_602433
proc url_GetGetSMSAttributes_603444(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetSMSAttributes_603443(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603445 = query.getOrDefault("attributes")
  valid_603445 = validateParameter(valid_603445, JArray, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "attributes", valid_603445
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603446 = query.getOrDefault("Action")
  valid_603446 = validateParameter(valid_603446, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_603446 != nil:
    section.add "Action", valid_603446
  var valid_603447 = query.getOrDefault("Version")
  valid_603447 = validateParameter(valid_603447, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603447 != nil:
    section.add "Version", valid_603447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603448 = header.getOrDefault("X-Amz-Date")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Date", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Security-Token")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Security-Token", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Content-Sha256", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Algorithm")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Algorithm", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Signature")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Signature", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-SignedHeaders", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Credential")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Credential", valid_603454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603455: Call_GetGetSMSAttributes_603442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_603455.validator(path, query, header, formData, body)
  let scheme = call_603455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603455.url(scheme.get, call_603455.host, call_603455.base,
                         call_603455.route, valid.getOrDefault("path"))
  result = hook(call_603455, url, valid)

proc call*(call_603456: Call_GetGetSMSAttributes_603442;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603457 = newJObject()
  if attributes != nil:
    query_603457.add "attributes", attributes
  add(query_603457, "Action", newJString(Action))
  add(query_603457, "Version", newJString(Version))
  result = call_603456.call(nil, query_603457, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_603442(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_603443, base: "/",
    url: url_GetGetSMSAttributes_603444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_603491 = ref object of OpenApiRestCall_602433
proc url_PostGetSubscriptionAttributes_603493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetSubscriptionAttributes_603492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603494 = query.getOrDefault("Action")
  valid_603494 = validateParameter(valid_603494, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_603494 != nil:
    section.add "Action", valid_603494
  var valid_603495 = query.getOrDefault("Version")
  valid_603495 = validateParameter(valid_603495, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603495 != nil:
    section.add "Version", valid_603495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603496 = header.getOrDefault("X-Amz-Date")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Date", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Security-Token")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Security-Token", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_603503 = formData.getOrDefault("SubscriptionArn")
  valid_603503 = validateParameter(valid_603503, JString, required = true,
                                 default = nil)
  if valid_603503 != nil:
    section.add "SubscriptionArn", valid_603503
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_PostGetSubscriptionAttributes_603491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_PostGetSubscriptionAttributes_603491;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Version: string (required)
  var query_603506 = newJObject()
  var formData_603507 = newJObject()
  add(query_603506, "Action", newJString(Action))
  add(formData_603507, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_603506, "Version", newJString(Version))
  result = call_603505.call(nil, query_603506, nil, formData_603507, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_603491(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_603492, base: "/",
    url: url_PostGetSubscriptionAttributes_603493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_603475 = ref object of OpenApiRestCall_602433
proc url_GetGetSubscriptionAttributes_603477(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetSubscriptionAttributes_603476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_603478 = query.getOrDefault("SubscriptionArn")
  valid_603478 = validateParameter(valid_603478, JString, required = true,
                                 default = nil)
  if valid_603478 != nil:
    section.add "SubscriptionArn", valid_603478
  var valid_603479 = query.getOrDefault("Action")
  valid_603479 = validateParameter(valid_603479, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_603479 != nil:
    section.add "Action", valid_603479
  var valid_603480 = query.getOrDefault("Version")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603480 != nil:
    section.add "Version", valid_603480
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603481 = header.getOrDefault("X-Amz-Date")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Date", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Security-Token")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Security-Token", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603488: Call_GetGetSubscriptionAttributes_603475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_603488.validator(path, query, header, formData, body)
  let scheme = call_603488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603488.url(scheme.get, call_603488.host, call_603488.base,
                         call_603488.route, valid.getOrDefault("path"))
  result = hook(call_603488, url, valid)

proc call*(call_603489: Call_GetGetSubscriptionAttributes_603475;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603490 = newJObject()
  add(query_603490, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_603490, "Action", newJString(Action))
  add(query_603490, "Version", newJString(Version))
  result = call_603489.call(nil, query_603490, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_603475(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_603476, base: "/",
    url: url_GetGetSubscriptionAttributes_603477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_603524 = ref object of OpenApiRestCall_602433
proc url_PostGetTopicAttributes_603526(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetTopicAttributes_603525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603527 = query.getOrDefault("Action")
  valid_603527 = validateParameter(valid_603527, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_603527 != nil:
    section.add "Action", valid_603527
  var valid_603528 = query.getOrDefault("Version")
  valid_603528 = validateParameter(valid_603528, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603528 != nil:
    section.add "Version", valid_603528
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603529 = header.getOrDefault("X-Amz-Date")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Date", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Security-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Security-Token", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Content-Sha256", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Algorithm")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Algorithm", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Signature")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Signature", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-SignedHeaders", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Credential")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Credential", valid_603535
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603536 = formData.getOrDefault("TopicArn")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = nil)
  if valid_603536 != nil:
    section.add "TopicArn", valid_603536
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603537: Call_PostGetTopicAttributes_603524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_603537.validator(path, query, header, formData, body)
  let scheme = call_603537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603537.url(scheme.get, call_603537.host, call_603537.base,
                         call_603537.route, valid.getOrDefault("path"))
  result = hook(call_603537, url, valid)

proc call*(call_603538: Call_PostGetTopicAttributes_603524; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603539 = newJObject()
  var formData_603540 = newJObject()
  add(formData_603540, "TopicArn", newJString(TopicArn))
  add(query_603539, "Action", newJString(Action))
  add(query_603539, "Version", newJString(Version))
  result = call_603538.call(nil, query_603539, nil, formData_603540, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_603524(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_603525, base: "/",
    url: url_PostGetTopicAttributes_603526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_603508 = ref object of OpenApiRestCall_602433
proc url_GetGetTopicAttributes_603510(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetTopicAttributes_603509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603511 = query.getOrDefault("Action")
  valid_603511 = validateParameter(valid_603511, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_603511 != nil:
    section.add "Action", valid_603511
  var valid_603512 = query.getOrDefault("TopicArn")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = nil)
  if valid_603512 != nil:
    section.add "TopicArn", valid_603512
  var valid_603513 = query.getOrDefault("Version")
  valid_603513 = validateParameter(valid_603513, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603513 != nil:
    section.add "Version", valid_603513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Content-Sha256", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Signature")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Signature", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-SignedHeaders", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Credential")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Credential", valid_603520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603521: Call_GetGetTopicAttributes_603508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_603521.validator(path, query, header, formData, body)
  let scheme = call_603521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603521.url(scheme.get, call_603521.host, call_603521.base,
                         call_603521.route, valid.getOrDefault("path"))
  result = hook(call_603521, url, valid)

proc call*(call_603522: Call_GetGetTopicAttributes_603508; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: string (required)
  var query_603523 = newJObject()
  add(query_603523, "Action", newJString(Action))
  add(query_603523, "TopicArn", newJString(TopicArn))
  add(query_603523, "Version", newJString(Version))
  result = call_603522.call(nil, query_603523, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_603508(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_603509, base: "/",
    url: url_GetGetTopicAttributes_603510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_603558 = ref object of OpenApiRestCall_602433
proc url_PostListEndpointsByPlatformApplication_603560(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListEndpointsByPlatformApplication_603559(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603561 = query.getOrDefault("Action")
  valid_603561 = validateParameter(valid_603561, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_603561 != nil:
    section.add "Action", valid_603561
  var valid_603562 = query.getOrDefault("Version")
  valid_603562 = validateParameter(valid_603562, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603562 != nil:
    section.add "Version", valid_603562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603563 = header.getOrDefault("X-Amz-Date")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Date", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Security-Token")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Security-Token", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Content-Sha256", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Algorithm")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Algorithm", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Signature")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Signature", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-SignedHeaders", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Credential")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Credential", valid_603569
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_603570 = formData.getOrDefault("NextToken")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "NextToken", valid_603570
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603571 = formData.getOrDefault("PlatformApplicationArn")
  valid_603571 = validateParameter(valid_603571, JString, required = true,
                                 default = nil)
  if valid_603571 != nil:
    section.add "PlatformApplicationArn", valid_603571
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603572: Call_PostListEndpointsByPlatformApplication_603558;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603572.validator(path, query, header, formData, body)
  let scheme = call_603572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603572.url(scheme.get, call_603572.host, call_603572.base,
                         call_603572.route, valid.getOrDefault("path"))
  result = hook(call_603572, url, valid)

proc call*(call_603573: Call_PostListEndpointsByPlatformApplication_603558;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Version: string (required)
  var query_603574 = newJObject()
  var formData_603575 = newJObject()
  add(formData_603575, "NextToken", newJString(NextToken))
  add(query_603574, "Action", newJString(Action))
  add(formData_603575, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_603574, "Version", newJString(Version))
  result = call_603573.call(nil, query_603574, nil, formData_603575, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_603558(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_603559, base: "/",
    url: url_PostListEndpointsByPlatformApplication_603560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_603541 = ref object of OpenApiRestCall_602433
proc url_GetListEndpointsByPlatformApplication_603543(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListEndpointsByPlatformApplication_603542(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_603544 = query.getOrDefault("NextToken")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "NextToken", valid_603544
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603545 = query.getOrDefault("Action")
  valid_603545 = validateParameter(valid_603545, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_603545 != nil:
    section.add "Action", valid_603545
  var valid_603546 = query.getOrDefault("Version")
  valid_603546 = validateParameter(valid_603546, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603546 != nil:
    section.add "Version", valid_603546
  var valid_603547 = query.getOrDefault("PlatformApplicationArn")
  valid_603547 = validateParameter(valid_603547, JString, required = true,
                                 default = nil)
  if valid_603547 != nil:
    section.add "PlatformApplicationArn", valid_603547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603548 = header.getOrDefault("X-Amz-Date")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Date", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Security-Token")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Security-Token", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Content-Sha256", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Algorithm")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Algorithm", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Signature")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Signature", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-SignedHeaders", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Credential")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Credential", valid_603554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603555: Call_GetListEndpointsByPlatformApplication_603541;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603555.validator(path, query, header, formData, body)
  let scheme = call_603555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603555.url(scheme.get, call_603555.host, call_603555.base,
                         call_603555.route, valid.getOrDefault("path"))
  result = hook(call_603555, url, valid)

proc call*(call_603556: Call_GetListEndpointsByPlatformApplication_603541;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  var query_603557 = newJObject()
  add(query_603557, "NextToken", newJString(NextToken))
  add(query_603557, "Action", newJString(Action))
  add(query_603557, "Version", newJString(Version))
  add(query_603557, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603556.call(nil, query_603557, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_603541(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_603542, base: "/",
    url: url_GetListEndpointsByPlatformApplication_603543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_603592 = ref object of OpenApiRestCall_602433
proc url_PostListPhoneNumbersOptedOut_603594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPhoneNumbersOptedOut_603593(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603595 = query.getOrDefault("Action")
  valid_603595 = validateParameter(valid_603595, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_603595 != nil:
    section.add "Action", valid_603595
  var valid_603596 = query.getOrDefault("Version")
  valid_603596 = validateParameter(valid_603596, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603596 != nil:
    section.add "Version", valid_603596
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603597 = header.getOrDefault("X-Amz-Date")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Date", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Security-Token")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Security-Token", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Content-Sha256", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Algorithm")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Algorithm", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Signature")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Signature", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-SignedHeaders", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Credential")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Credential", valid_603603
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_603604 = formData.getOrDefault("nextToken")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "nextToken", valid_603604
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603605: Call_PostListPhoneNumbersOptedOut_603592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_603605.validator(path, query, header, formData, body)
  let scheme = call_603605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603605.url(scheme.get, call_603605.host, call_603605.base,
                         call_603605.route, valid.getOrDefault("path"))
  result = hook(call_603605, url, valid)

proc call*(call_603606: Call_PostListPhoneNumbersOptedOut_603592;
          Action: string = "ListPhoneNumbersOptedOut"; nextToken: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   Action: string (required)
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Version: string (required)
  var query_603607 = newJObject()
  var formData_603608 = newJObject()
  add(query_603607, "Action", newJString(Action))
  add(formData_603608, "nextToken", newJString(nextToken))
  add(query_603607, "Version", newJString(Version))
  result = call_603606.call(nil, query_603607, nil, formData_603608, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_603592(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_603593, base: "/",
    url: url_PostListPhoneNumbersOptedOut_603594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_603576 = ref object of OpenApiRestCall_602433
proc url_GetListPhoneNumbersOptedOut_603578(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPhoneNumbersOptedOut_603577(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603579 = query.getOrDefault("nextToken")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "nextToken", valid_603579
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603580 = query.getOrDefault("Action")
  valid_603580 = validateParameter(valid_603580, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_603580 != nil:
    section.add "Action", valid_603580
  var valid_603581 = query.getOrDefault("Version")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603581 != nil:
    section.add "Version", valid_603581
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603582 = header.getOrDefault("X-Amz-Date")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Date", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Security-Token")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Security-Token", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Content-Sha256", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Algorithm")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Algorithm", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-SignedHeaders", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Credential")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Credential", valid_603588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603589: Call_GetListPhoneNumbersOptedOut_603576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_603589.validator(path, query, header, formData, body)
  let scheme = call_603589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603589.url(scheme.get, call_603589.host, call_603589.base,
                         call_603589.route, valid.getOrDefault("path"))
  result = hook(call_603589, url, valid)

proc call*(call_603590: Call_GetListPhoneNumbersOptedOut_603576;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603591 = newJObject()
  add(query_603591, "nextToken", newJString(nextToken))
  add(query_603591, "Action", newJString(Action))
  add(query_603591, "Version", newJString(Version))
  result = call_603590.call(nil, query_603591, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_603576(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_603577, base: "/",
    url: url_GetListPhoneNumbersOptedOut_603578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_603625 = ref object of OpenApiRestCall_602433
proc url_PostListPlatformApplications_603627(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPlatformApplications_603626(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603628 = query.getOrDefault("Action")
  valid_603628 = validateParameter(valid_603628, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_603628 != nil:
    section.add "Action", valid_603628
  var valid_603629 = query.getOrDefault("Version")
  valid_603629 = validateParameter(valid_603629, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603629 != nil:
    section.add "Version", valid_603629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Security-Token")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Security-Token", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Content-Sha256", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Algorithm")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Algorithm", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Signature")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Signature", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-SignedHeaders", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Credential")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Credential", valid_603636
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_603637 = formData.getOrDefault("NextToken")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "NextToken", valid_603637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603638: Call_PostListPlatformApplications_603625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_603638.validator(path, query, header, formData, body)
  let scheme = call_603638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603638.url(scheme.get, call_603638.host, call_603638.base,
                         call_603638.route, valid.getOrDefault("path"))
  result = hook(call_603638, url, valid)

proc call*(call_603639: Call_PostListPlatformApplications_603625;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603640 = newJObject()
  var formData_603641 = newJObject()
  add(formData_603641, "NextToken", newJString(NextToken))
  add(query_603640, "Action", newJString(Action))
  add(query_603640, "Version", newJString(Version))
  result = call_603639.call(nil, query_603640, nil, formData_603641, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_603625(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_603626, base: "/",
    url: url_PostListPlatformApplications_603627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_603609 = ref object of OpenApiRestCall_602433
proc url_GetListPlatformApplications_603611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPlatformApplications_603610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603612 = query.getOrDefault("NextToken")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "NextToken", valid_603612
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603613 = query.getOrDefault("Action")
  valid_603613 = validateParameter(valid_603613, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_603613 != nil:
    section.add "Action", valid_603613
  var valid_603614 = query.getOrDefault("Version")
  valid_603614 = validateParameter(valid_603614, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603614 != nil:
    section.add "Version", valid_603614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Content-Sha256", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Algorithm")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Algorithm", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Signature")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Signature", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-SignedHeaders", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Credential")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Credential", valid_603621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_GetListPlatformApplications_603609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"))
  result = hook(call_603622, url, valid)

proc call*(call_603623: Call_GetListPlatformApplications_603609;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603624 = newJObject()
  add(query_603624, "NextToken", newJString(NextToken))
  add(query_603624, "Action", newJString(Action))
  add(query_603624, "Version", newJString(Version))
  result = call_603623.call(nil, query_603624, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_603609(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_603610, base: "/",
    url: url_GetListPlatformApplications_603611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_603658 = ref object of OpenApiRestCall_602433
proc url_PostListSubscriptions_603660(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListSubscriptions_603659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603661 = query.getOrDefault("Action")
  valid_603661 = validateParameter(valid_603661, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_603661 != nil:
    section.add "Action", valid_603661
  var valid_603662 = query.getOrDefault("Version")
  valid_603662 = validateParameter(valid_603662, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603662 != nil:
    section.add "Version", valid_603662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603663 = header.getOrDefault("X-Amz-Date")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Date", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Security-Token")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Security-Token", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Content-Sha256", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Algorithm")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Algorithm", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Signature")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Signature", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-SignedHeaders", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Credential")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Credential", valid_603669
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_603670 = formData.getOrDefault("NextToken")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "NextToken", valid_603670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603671: Call_PostListSubscriptions_603658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603671.validator(path, query, header, formData, body)
  let scheme = call_603671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603671.url(scheme.get, call_603671.host, call_603671.base,
                         call_603671.route, valid.getOrDefault("path"))
  result = hook(call_603671, url, valid)

proc call*(call_603672: Call_PostListSubscriptions_603658; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603673 = newJObject()
  var formData_603674 = newJObject()
  add(formData_603674, "NextToken", newJString(NextToken))
  add(query_603673, "Action", newJString(Action))
  add(query_603673, "Version", newJString(Version))
  result = call_603672.call(nil, query_603673, nil, formData_603674, nil)

var postListSubscriptions* = Call_PostListSubscriptions_603658(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_603659, base: "/",
    url: url_PostListSubscriptions_603660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_603642 = ref object of OpenApiRestCall_602433
proc url_GetListSubscriptions_603644(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListSubscriptions_603643(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603645 = query.getOrDefault("NextToken")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "NextToken", valid_603645
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603646 = query.getOrDefault("Action")
  valid_603646 = validateParameter(valid_603646, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_603646 != nil:
    section.add "Action", valid_603646
  var valid_603647 = query.getOrDefault("Version")
  valid_603647 = validateParameter(valid_603647, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603647 != nil:
    section.add "Version", valid_603647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603648 = header.getOrDefault("X-Amz-Date")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Date", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Security-Token")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Security-Token", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Content-Sha256", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Algorithm")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Algorithm", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Signature")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Signature", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-SignedHeaders", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Credential")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Credential", valid_603654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603655: Call_GetListSubscriptions_603642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603655.validator(path, query, header, formData, body)
  let scheme = call_603655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603655.url(scheme.get, call_603655.host, call_603655.base,
                         call_603655.route, valid.getOrDefault("path"))
  result = hook(call_603655, url, valid)

proc call*(call_603656: Call_GetListSubscriptions_603642; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603657 = newJObject()
  add(query_603657, "NextToken", newJString(NextToken))
  add(query_603657, "Action", newJString(Action))
  add(query_603657, "Version", newJString(Version))
  result = call_603656.call(nil, query_603657, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_603642(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_603643, base: "/",
    url: url_GetListSubscriptions_603644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_603692 = ref object of OpenApiRestCall_602433
proc url_PostListSubscriptionsByTopic_603694(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListSubscriptionsByTopic_603693(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603695 = query.getOrDefault("Action")
  valid_603695 = validateParameter(valid_603695, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_603695 != nil:
    section.add "Action", valid_603695
  var valid_603696 = query.getOrDefault("Version")
  valid_603696 = validateParameter(valid_603696, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603696 != nil:
    section.add "Version", valid_603696
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603697 = header.getOrDefault("X-Amz-Date")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Date", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Security-Token")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Security-Token", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Content-Sha256", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Algorithm")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Algorithm", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Signature")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Signature", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-SignedHeaders", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Credential")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Credential", valid_603703
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_603704 = formData.getOrDefault("NextToken")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "NextToken", valid_603704
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603705 = formData.getOrDefault("TopicArn")
  valid_603705 = validateParameter(valid_603705, JString, required = true,
                                 default = nil)
  if valid_603705 != nil:
    section.add "TopicArn", valid_603705
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603706: Call_PostListSubscriptionsByTopic_603692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603706.validator(path, query, header, formData, body)
  let scheme = call_603706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603706.url(scheme.get, call_603706.host, call_603706.base,
                         call_603706.route, valid.getOrDefault("path"))
  result = hook(call_603706, url, valid)

proc call*(call_603707: Call_PostListSubscriptionsByTopic_603692; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603708 = newJObject()
  var formData_603709 = newJObject()
  add(formData_603709, "NextToken", newJString(NextToken))
  add(formData_603709, "TopicArn", newJString(TopicArn))
  add(query_603708, "Action", newJString(Action))
  add(query_603708, "Version", newJString(Version))
  result = call_603707.call(nil, query_603708, nil, formData_603709, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_603692(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_603693, base: "/",
    url: url_PostListSubscriptionsByTopic_603694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_603675 = ref object of OpenApiRestCall_602433
proc url_GetListSubscriptionsByTopic_603677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListSubscriptionsByTopic_603676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603678 = query.getOrDefault("NextToken")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "NextToken", valid_603678
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603679 = query.getOrDefault("Action")
  valid_603679 = validateParameter(valid_603679, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_603679 != nil:
    section.add "Action", valid_603679
  var valid_603680 = query.getOrDefault("TopicArn")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = nil)
  if valid_603680 != nil:
    section.add "TopicArn", valid_603680
  var valid_603681 = query.getOrDefault("Version")
  valid_603681 = validateParameter(valid_603681, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603681 != nil:
    section.add "Version", valid_603681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603682 = header.getOrDefault("X-Amz-Date")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Date", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Security-Token")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Security-Token", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Content-Sha256", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Algorithm")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Algorithm", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Signature")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Signature", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-SignedHeaders", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Credential")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Credential", valid_603688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603689: Call_GetListSubscriptionsByTopic_603675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603689.validator(path, query, header, formData, body)
  let scheme = call_603689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603689.url(scheme.get, call_603689.host, call_603689.base,
                         call_603689.route, valid.getOrDefault("path"))
  result = hook(call_603689, url, valid)

proc call*(call_603690: Call_GetListSubscriptionsByTopic_603675; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Version: string (required)
  var query_603691 = newJObject()
  add(query_603691, "NextToken", newJString(NextToken))
  add(query_603691, "Action", newJString(Action))
  add(query_603691, "TopicArn", newJString(TopicArn))
  add(query_603691, "Version", newJString(Version))
  result = call_603690.call(nil, query_603691, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_603675(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_603676, base: "/",
    url: url_GetListSubscriptionsByTopic_603677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603726 = ref object of OpenApiRestCall_602433
proc url_PostListTagsForResource_603728(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_603727(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603729 = query.getOrDefault("Action")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603729 != nil:
    section.add "Action", valid_603729
  var valid_603730 = query.getOrDefault("Version")
  valid_603730 = validateParameter(valid_603730, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603730 != nil:
    section.add "Version", valid_603730
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603731 = header.getOrDefault("X-Amz-Date")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Date", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Security-Token")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Security-Token", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Content-Sha256", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Algorithm")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Algorithm", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Signature")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Signature", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-SignedHeaders", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Credential")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Credential", valid_603737
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_603738 = formData.getOrDefault("ResourceArn")
  valid_603738 = validateParameter(valid_603738, JString, required = true,
                                 default = nil)
  if valid_603738 != nil:
    section.add "ResourceArn", valid_603738
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603739: Call_PostListTagsForResource_603726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_603739.validator(path, query, header, formData, body)
  let scheme = call_603739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603739.url(scheme.get, call_603739.host, call_603739.base,
                         call_603739.route, valid.getOrDefault("path"))
  result = hook(call_603739, url, valid)

proc call*(call_603740: Call_PostListTagsForResource_603726; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Version: string (required)
  var query_603741 = newJObject()
  var formData_603742 = newJObject()
  add(query_603741, "Action", newJString(Action))
  add(formData_603742, "ResourceArn", newJString(ResourceArn))
  add(query_603741, "Version", newJString(Version))
  result = call_603740.call(nil, query_603741, nil, formData_603742, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603726(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603727, base: "/",
    url: url_PostListTagsForResource_603728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603710 = ref object of OpenApiRestCall_602433
proc url_GetListTagsForResource_603712(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_603711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_603713 = query.getOrDefault("ResourceArn")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "ResourceArn", valid_603713
  var valid_603714 = query.getOrDefault("Action")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603714 != nil:
    section.add "Action", valid_603714
  var valid_603715 = query.getOrDefault("Version")
  valid_603715 = validateParameter(valid_603715, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603715 != nil:
    section.add "Version", valid_603715
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603716 = header.getOrDefault("X-Amz-Date")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Date", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Security-Token")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Security-Token", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Content-Sha256", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Algorithm")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Algorithm", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Signature")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Signature", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-SignedHeaders", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Credential")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Credential", valid_603722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603723: Call_GetListTagsForResource_603710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_603723.validator(path, query, header, formData, body)
  let scheme = call_603723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603723.url(scheme.get, call_603723.host, call_603723.base,
                         call_603723.route, valid.getOrDefault("path"))
  result = hook(call_603723, url, valid)

proc call*(call_603724: Call_GetListTagsForResource_603710; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603725 = newJObject()
  add(query_603725, "ResourceArn", newJString(ResourceArn))
  add(query_603725, "Action", newJString(Action))
  add(query_603725, "Version", newJString(Version))
  result = call_603724.call(nil, query_603725, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603710(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603711, base: "/",
    url: url_GetListTagsForResource_603712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_603759 = ref object of OpenApiRestCall_602433
proc url_PostListTopics_603761(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTopics_603760(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603762 = query.getOrDefault("Action")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_603762 != nil:
    section.add "Action", valid_603762
  var valid_603763 = query.getOrDefault("Version")
  valid_603763 = validateParameter(valid_603763, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603763 != nil:
    section.add "Version", valid_603763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603764 = header.getOrDefault("X-Amz-Date")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Date", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Security-Token")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Security-Token", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Content-Sha256", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Algorithm")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Algorithm", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Signature")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Signature", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-SignedHeaders", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Credential")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Credential", valid_603770
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_603771 = formData.getOrDefault("NextToken")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "NextToken", valid_603771
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603772: Call_PostListTopics_603759; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603772.validator(path, query, header, formData, body)
  let scheme = call_603772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603772.url(scheme.get, call_603772.host, call_603772.base,
                         call_603772.route, valid.getOrDefault("path"))
  result = hook(call_603772, url, valid)

proc call*(call_603773: Call_PostListTopics_603759; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603774 = newJObject()
  var formData_603775 = newJObject()
  add(formData_603775, "NextToken", newJString(NextToken))
  add(query_603774, "Action", newJString(Action))
  add(query_603774, "Version", newJString(Version))
  result = call_603773.call(nil, query_603774, nil, formData_603775, nil)

var postListTopics* = Call_PostListTopics_603759(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_603760,
    base: "/", url: url_PostListTopics_603761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_603743 = ref object of OpenApiRestCall_602433
proc url_GetListTopics_603745(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTopics_603744(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603746 = query.getOrDefault("NextToken")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "NextToken", valid_603746
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603747 = query.getOrDefault("Action")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_603747 != nil:
    section.add "Action", valid_603747
  var valid_603748 = query.getOrDefault("Version")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603748 != nil:
    section.add "Version", valid_603748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603749 = header.getOrDefault("X-Amz-Date")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Date", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Security-Token")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Security-Token", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Content-Sha256", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Algorithm")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Algorithm", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Signature")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Signature", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-SignedHeaders", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Credential")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Credential", valid_603755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603756: Call_GetListTopics_603743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_603756.validator(path, query, header, formData, body)
  let scheme = call_603756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603756.url(scheme.get, call_603756.host, call_603756.base,
                         call_603756.route, valid.getOrDefault("path"))
  result = hook(call_603756, url, valid)

proc call*(call_603757: Call_GetListTopics_603743; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603758 = newJObject()
  add(query_603758, "NextToken", newJString(NextToken))
  add(query_603758, "Action", newJString(Action))
  add(query_603758, "Version", newJString(Version))
  result = call_603757.call(nil, query_603758, nil, nil, nil)

var getListTopics* = Call_GetListTopics_603743(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_603744,
    base: "/", url: url_GetListTopics_603745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_603792 = ref object of OpenApiRestCall_602433
proc url_PostOptInPhoneNumber_603794(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostOptInPhoneNumber_603793(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603795 = query.getOrDefault("Action")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_603795 != nil:
    section.add "Action", valid_603795
  var valid_603796 = query.getOrDefault("Version")
  valid_603796 = validateParameter(valid_603796, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603796 != nil:
    section.add "Version", valid_603796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603797 = header.getOrDefault("X-Amz-Date")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Date", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Security-Token")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Security-Token", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Content-Sha256", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Algorithm")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Algorithm", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Signature")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Signature", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-SignedHeaders", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Credential")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Credential", valid_603803
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_603804 = formData.getOrDefault("phoneNumber")
  valid_603804 = validateParameter(valid_603804, JString, required = true,
                                 default = nil)
  if valid_603804 != nil:
    section.add "phoneNumber", valid_603804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603805: Call_PostOptInPhoneNumber_603792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_603805.validator(path, query, header, formData, body)
  let scheme = call_603805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603805.url(scheme.get, call_603805.host, call_603805.base,
                         call_603805.route, valid.getOrDefault("path"))
  result = hook(call_603805, url, valid)

proc call*(call_603806: Call_PostOptInPhoneNumber_603792; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Version: string (required)
  var query_603807 = newJObject()
  var formData_603808 = newJObject()
  add(query_603807, "Action", newJString(Action))
  add(formData_603808, "phoneNumber", newJString(phoneNumber))
  add(query_603807, "Version", newJString(Version))
  result = call_603806.call(nil, query_603807, nil, formData_603808, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_603792(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_603793, base: "/",
    url: url_PostOptInPhoneNumber_603794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_603776 = ref object of OpenApiRestCall_602433
proc url_GetOptInPhoneNumber_603778(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOptInPhoneNumber_603777(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_603779 = query.getOrDefault("phoneNumber")
  valid_603779 = validateParameter(valid_603779, JString, required = true,
                                 default = nil)
  if valid_603779 != nil:
    section.add "phoneNumber", valid_603779
  var valid_603780 = query.getOrDefault("Action")
  valid_603780 = validateParameter(valid_603780, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_603780 != nil:
    section.add "Action", valid_603780
  var valid_603781 = query.getOrDefault("Version")
  valid_603781 = validateParameter(valid_603781, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603781 != nil:
    section.add "Version", valid_603781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603782 = header.getOrDefault("X-Amz-Date")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Date", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Security-Token")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Security-Token", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Content-Sha256", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Algorithm")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Algorithm", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Signature")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Signature", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-SignedHeaders", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Credential")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Credential", valid_603788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603789: Call_GetOptInPhoneNumber_603776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_603789.validator(path, query, header, formData, body)
  let scheme = call_603789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603789.url(scheme.get, call_603789.host, call_603789.base,
                         call_603789.route, valid.getOrDefault("path"))
  result = hook(call_603789, url, valid)

proc call*(call_603790: Call_GetOptInPhoneNumber_603776; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603791 = newJObject()
  add(query_603791, "phoneNumber", newJString(phoneNumber))
  add(query_603791, "Action", newJString(Action))
  add(query_603791, "Version", newJString(Version))
  result = call_603790.call(nil, query_603791, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_603776(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_603777, base: "/",
    url: url_GetOptInPhoneNumber_603778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_603836 = ref object of OpenApiRestCall_602433
proc url_PostPublish_603838(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPublish_603837(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603839 = query.getOrDefault("Action")
  valid_603839 = validateParameter(valid_603839, JString, required = true,
                                 default = newJString("Publish"))
  if valid_603839 != nil:
    section.add "Action", valid_603839
  var valid_603840 = query.getOrDefault("Version")
  valid_603840 = validateParameter(valid_603840, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603840 != nil:
    section.add "Version", valid_603840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603841 = header.getOrDefault("X-Amz-Date")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Date", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Security-Token")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Security-Token", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Content-Sha256", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Algorithm")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Algorithm", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Signature")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Signature", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-SignedHeaders", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Credential")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Credential", valid_603847
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.1.key: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.1.value: JString
  ##   MessageAttributes.0.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.2.key: JString
  ##   MessageAttributes.2.value: JString
  section = newJObject()
  var valid_603848 = formData.getOrDefault("TopicArn")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "TopicArn", valid_603848
  var valid_603849 = formData.getOrDefault("Subject")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "Subject", valid_603849
  var valid_603850 = formData.getOrDefault("MessageAttributes.1.key")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "MessageAttributes.1.key", valid_603850
  var valid_603851 = formData.getOrDefault("TargetArn")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "TargetArn", valid_603851
  var valid_603852 = formData.getOrDefault("PhoneNumber")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "PhoneNumber", valid_603852
  var valid_603853 = formData.getOrDefault("MessageAttributes.0.value")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "MessageAttributes.0.value", valid_603853
  var valid_603854 = formData.getOrDefault("MessageAttributes.1.value")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "MessageAttributes.1.value", valid_603854
  var valid_603855 = formData.getOrDefault("MessageAttributes.0.key")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "MessageAttributes.0.key", valid_603855
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_603856 = formData.getOrDefault("Message")
  valid_603856 = validateParameter(valid_603856, JString, required = true,
                                 default = nil)
  if valid_603856 != nil:
    section.add "Message", valid_603856
  var valid_603857 = formData.getOrDefault("MessageStructure")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "MessageStructure", valid_603857
  var valid_603858 = formData.getOrDefault("MessageAttributes.2.key")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "MessageAttributes.2.key", valid_603858
  var valid_603859 = formData.getOrDefault("MessageAttributes.2.value")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "MessageAttributes.2.value", valid_603859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603860: Call_PostPublish_603836; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_603860.validator(path, query, header, formData, body)
  let scheme = call_603860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603860.url(scheme.get, call_603860.host, call_603860.base,
                         call_603860.route, valid.getOrDefault("path"))
  result = hook(call_603860, url, valid)

proc call*(call_603861: Call_PostPublish_603836; Message: string;
          TopicArn: string = ""; Subject: string = "";
          MessageAttributes1Key: string = ""; TargetArn: string = "";
          PhoneNumber: string = ""; MessageAttributes0Value: string = "";
          MessageAttributes1Value: string = ""; MessageAttributes0Key: string = "";
          Action: string = "Publish"; MessageStructure: string = "";
          MessageAttributes2Key: string = ""; Version: string = "2010-03-31";
          MessageAttributes2Value: string = ""): Recallable =
  ## postPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes1Key: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes1Value: string
  ##   MessageAttributes0Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Action: string (required)
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes2Key: string
  ##   Version: string (required)
  ##   MessageAttributes2Value: string
  var query_603862 = newJObject()
  var formData_603863 = newJObject()
  add(formData_603863, "TopicArn", newJString(TopicArn))
  add(formData_603863, "Subject", newJString(Subject))
  add(formData_603863, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_603863, "TargetArn", newJString(TargetArn))
  add(formData_603863, "PhoneNumber", newJString(PhoneNumber))
  add(formData_603863, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_603863, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_603863, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_603863, "Message", newJString(Message))
  add(query_603862, "Action", newJString(Action))
  add(formData_603863, "MessageStructure", newJString(MessageStructure))
  add(formData_603863, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(query_603862, "Version", newJString(Version))
  add(formData_603863, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  result = call_603861.call(nil, query_603862, nil, formData_603863, nil)

var postPublish* = Call_PostPublish_603836(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_603837,
                                        base: "/", url: url_PostPublish_603838,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_603809 = ref object of OpenApiRestCall_602433
proc url_GetPublish_603811(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPublish_603810(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.0.key: JString
  ##   MessageAttributes.1.value: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: JString (required)
  ##   MessageAttributes.2.value: JString
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.1.key: JString
  ##   MessageAttributes.2.key: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603812 = query.getOrDefault("MessageAttributes.0.value")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "MessageAttributes.0.value", valid_603812
  var valid_603813 = query.getOrDefault("MessageAttributes.0.key")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "MessageAttributes.0.key", valid_603813
  var valid_603814 = query.getOrDefault("MessageAttributes.1.value")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "MessageAttributes.1.value", valid_603814
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_603815 = query.getOrDefault("Message")
  valid_603815 = validateParameter(valid_603815, JString, required = true,
                                 default = nil)
  if valid_603815 != nil:
    section.add "Message", valid_603815
  var valid_603816 = query.getOrDefault("Subject")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "Subject", valid_603816
  var valid_603817 = query.getOrDefault("Action")
  valid_603817 = validateParameter(valid_603817, JString, required = true,
                                 default = newJString("Publish"))
  if valid_603817 != nil:
    section.add "Action", valid_603817
  var valid_603818 = query.getOrDefault("MessageAttributes.2.value")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "MessageAttributes.2.value", valid_603818
  var valid_603819 = query.getOrDefault("MessageStructure")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "MessageStructure", valid_603819
  var valid_603820 = query.getOrDefault("TopicArn")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "TopicArn", valid_603820
  var valid_603821 = query.getOrDefault("PhoneNumber")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "PhoneNumber", valid_603821
  var valid_603822 = query.getOrDefault("MessageAttributes.1.key")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "MessageAttributes.1.key", valid_603822
  var valid_603823 = query.getOrDefault("MessageAttributes.2.key")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "MessageAttributes.2.key", valid_603823
  var valid_603824 = query.getOrDefault("TargetArn")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "TargetArn", valid_603824
  var valid_603825 = query.getOrDefault("Version")
  valid_603825 = validateParameter(valid_603825, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603825 != nil:
    section.add "Version", valid_603825
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603826 = header.getOrDefault("X-Amz-Date")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Date", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Security-Token")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Security-Token", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Content-Sha256", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Algorithm")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Algorithm", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Signature")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Signature", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-SignedHeaders", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Credential")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Credential", valid_603832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603833: Call_GetPublish_603809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_603833.validator(path, query, header, formData, body)
  let scheme = call_603833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603833.url(scheme.get, call_603833.host, call_603833.base,
                         call_603833.route, valid.getOrDefault("path"))
  result = hook(call_603833, url, valid)

proc call*(call_603834: Call_GetPublish_603809; Message: string;
          MessageAttributes0Value: string = ""; MessageAttributes0Key: string = "";
          MessageAttributes1Value: string = ""; Subject: string = "";
          Action: string = "Publish"; MessageAttributes2Value: string = "";
          MessageStructure: string = ""; TopicArn: string = "";
          PhoneNumber: string = ""; MessageAttributes1Key: string = "";
          MessageAttributes2Key: string = ""; TargetArn: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes0Key: string
  ##   MessageAttributes1Value: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: string (required)
  ##   MessageAttributes2Value: string
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes1Key: string
  ##   MessageAttributes2Key: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: string (required)
  var query_603835 = newJObject()
  add(query_603835, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_603835, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_603835, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_603835, "Message", newJString(Message))
  add(query_603835, "Subject", newJString(Subject))
  add(query_603835, "Action", newJString(Action))
  add(query_603835, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_603835, "MessageStructure", newJString(MessageStructure))
  add(query_603835, "TopicArn", newJString(TopicArn))
  add(query_603835, "PhoneNumber", newJString(PhoneNumber))
  add(query_603835, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_603835, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_603835, "TargetArn", newJString(TargetArn))
  add(query_603835, "Version", newJString(Version))
  result = call_603834.call(nil, query_603835, nil, nil, nil)

var getPublish* = Call_GetPublish_603809(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_603810,
                                      base: "/", url: url_GetPublish_603811,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_603881 = ref object of OpenApiRestCall_602433
proc url_PostRemovePermission_603883(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemovePermission_603882(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603884 = query.getOrDefault("Action")
  valid_603884 = validateParameter(valid_603884, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_603884 != nil:
    section.add "Action", valid_603884
  var valid_603885 = query.getOrDefault("Version")
  valid_603885 = validateParameter(valid_603885, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603885 != nil:
    section.add "Version", valid_603885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603886 = header.getOrDefault("X-Amz-Date")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Date", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Security-Token")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Security-Token", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Content-Sha256", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Algorithm")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Algorithm", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Signature")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Signature", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-SignedHeaders", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-Credential")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Credential", valid_603892
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_603893 = formData.getOrDefault("TopicArn")
  valid_603893 = validateParameter(valid_603893, JString, required = true,
                                 default = nil)
  if valid_603893 != nil:
    section.add "TopicArn", valid_603893
  var valid_603894 = formData.getOrDefault("Label")
  valid_603894 = validateParameter(valid_603894, JString, required = true,
                                 default = nil)
  if valid_603894 != nil:
    section.add "Label", valid_603894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603895: Call_PostRemovePermission_603881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_603895.validator(path, query, header, formData, body)
  let scheme = call_603895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603895.url(scheme.get, call_603895.host, call_603895.base,
                         call_603895.route, valid.getOrDefault("path"))
  result = hook(call_603895, url, valid)

proc call*(call_603896: Call_PostRemovePermission_603881; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## postRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603897 = newJObject()
  var formData_603898 = newJObject()
  add(formData_603898, "TopicArn", newJString(TopicArn))
  add(formData_603898, "Label", newJString(Label))
  add(query_603897, "Action", newJString(Action))
  add(query_603897, "Version", newJString(Version))
  result = call_603896.call(nil, query_603897, nil, formData_603898, nil)

var postRemovePermission* = Call_PostRemovePermission_603881(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_603882, base: "/",
    url: url_PostRemovePermission_603883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_603864 = ref object of OpenApiRestCall_602433
proc url_GetRemovePermission_603866(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemovePermission_603865(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603867 = query.getOrDefault("Action")
  valid_603867 = validateParameter(valid_603867, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_603867 != nil:
    section.add "Action", valid_603867
  var valid_603868 = query.getOrDefault("TopicArn")
  valid_603868 = validateParameter(valid_603868, JString, required = true,
                                 default = nil)
  if valid_603868 != nil:
    section.add "TopicArn", valid_603868
  var valid_603869 = query.getOrDefault("Version")
  valid_603869 = validateParameter(valid_603869, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603869 != nil:
    section.add "Version", valid_603869
  var valid_603870 = query.getOrDefault("Label")
  valid_603870 = validateParameter(valid_603870, JString, required = true,
                                 default = nil)
  if valid_603870 != nil:
    section.add "Label", valid_603870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603871 = header.getOrDefault("X-Amz-Date")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Date", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Security-Token")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Security-Token", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Content-Sha256", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Algorithm")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Algorithm", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Signature")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Signature", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-SignedHeaders", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Credential")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Credential", valid_603877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603878: Call_GetRemovePermission_603864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_603878.validator(path, query, header, formData, body)
  let scheme = call_603878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603878.url(scheme.get, call_603878.host, call_603878.base,
                         call_603878.route, valid.getOrDefault("path"))
  result = hook(call_603878, url, valid)

proc call*(call_603879: Call_GetRemovePermission_603864; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## getRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  var query_603880 = newJObject()
  add(query_603880, "Action", newJString(Action))
  add(query_603880, "TopicArn", newJString(TopicArn))
  add(query_603880, "Version", newJString(Version))
  add(query_603880, "Label", newJString(Label))
  result = call_603879.call(nil, query_603880, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_603864(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_603865, base: "/",
    url: url_GetRemovePermission_603866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_603921 = ref object of OpenApiRestCall_602433
proc url_PostSetEndpointAttributes_603923(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetEndpointAttributes_603922(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603924 = query.getOrDefault("Action")
  valid_603924 = validateParameter(valid_603924, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_603924 != nil:
    section.add "Action", valid_603924
  var valid_603925 = query.getOrDefault("Version")
  valid_603925 = validateParameter(valid_603925, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603925 != nil:
    section.add "Version", valid_603925
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603926 = header.getOrDefault("X-Amz-Date")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Date", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Security-Token")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Security-Token", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Content-Sha256", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Algorithm")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Algorithm", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-Signature")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Signature", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-SignedHeaders", valid_603931
  var valid_603932 = header.getOrDefault("X-Amz-Credential")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "X-Amz-Credential", valid_603932
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_603933 = formData.getOrDefault("Attributes.0.value")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "Attributes.0.value", valid_603933
  var valid_603934 = formData.getOrDefault("Attributes.0.key")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "Attributes.0.key", valid_603934
  var valid_603935 = formData.getOrDefault("Attributes.1.key")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "Attributes.1.key", valid_603935
  var valid_603936 = formData.getOrDefault("Attributes.2.value")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "Attributes.2.value", valid_603936
  var valid_603937 = formData.getOrDefault("Attributes.2.key")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "Attributes.2.key", valid_603937
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_603938 = formData.getOrDefault("EndpointArn")
  valid_603938 = validateParameter(valid_603938, JString, required = true,
                                 default = nil)
  if valid_603938 != nil:
    section.add "EndpointArn", valid_603938
  var valid_603939 = formData.getOrDefault("Attributes.1.value")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "Attributes.1.value", valid_603939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603940: Call_PostSetEndpointAttributes_603921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603940.validator(path, query, header, formData, body)
  let scheme = call_603940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603940.url(scheme.get, call_603940.host, call_603940.base,
                         call_603940.route, valid.getOrDefault("path"))
  result = hook(call_603940, url, valid)

proc call*(call_603941: Call_PostSetEndpointAttributes_603921; EndpointArn: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "SetEndpointAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_603942 = newJObject()
  var formData_603943 = newJObject()
  add(formData_603943, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603943, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603943, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603942, "Action", newJString(Action))
  add(formData_603943, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603943, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_603943, "EndpointArn", newJString(EndpointArn))
  add(query_603942, "Version", newJString(Version))
  add(formData_603943, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603941.call(nil, query_603942, nil, formData_603943, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_603921(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_603922, base: "/",
    url: url_PostSetEndpointAttributes_603923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_603899 = ref object of OpenApiRestCall_602433
proc url_GetSetEndpointAttributes_603901(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetEndpointAttributes_603900(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_603902 = query.getOrDefault("EndpointArn")
  valid_603902 = validateParameter(valid_603902, JString, required = true,
                                 default = nil)
  if valid_603902 != nil:
    section.add "EndpointArn", valid_603902
  var valid_603903 = query.getOrDefault("Attributes.2.key")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "Attributes.2.key", valid_603903
  var valid_603904 = query.getOrDefault("Attributes.1.value")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "Attributes.1.value", valid_603904
  var valid_603905 = query.getOrDefault("Attributes.0.value")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "Attributes.0.value", valid_603905
  var valid_603906 = query.getOrDefault("Action")
  valid_603906 = validateParameter(valid_603906, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_603906 != nil:
    section.add "Action", valid_603906
  var valid_603907 = query.getOrDefault("Attributes.1.key")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "Attributes.1.key", valid_603907
  var valid_603908 = query.getOrDefault("Attributes.2.value")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "Attributes.2.value", valid_603908
  var valid_603909 = query.getOrDefault("Attributes.0.key")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "Attributes.0.key", valid_603909
  var valid_603910 = query.getOrDefault("Version")
  valid_603910 = validateParameter(valid_603910, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603910 != nil:
    section.add "Version", valid_603910
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603911 = header.getOrDefault("X-Amz-Date")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Date", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Security-Token")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Security-Token", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Content-Sha256", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Algorithm")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Algorithm", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Signature")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Signature", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-SignedHeaders", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Credential")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Credential", valid_603917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603918: Call_GetSetEndpointAttributes_603899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_603918.validator(path, query, header, formData, body)
  let scheme = call_603918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603918.url(scheme.get, call_603918.host, call_603918.base,
                         call_603918.route, valid.getOrDefault("path"))
  result = hook(call_603918, url, valid)

proc call*(call_603919: Call_GetSetEndpointAttributes_603899; EndpointArn: string;
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "SetEndpointAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes2Key: string
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_603920 = newJObject()
  add(query_603920, "EndpointArn", newJString(EndpointArn))
  add(query_603920, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603920, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603920, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603920, "Action", newJString(Action))
  add(query_603920, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603920, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603920, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603920, "Version", newJString(Version))
  result = call_603919.call(nil, query_603920, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_603899(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_603900, base: "/",
    url: url_GetSetEndpointAttributes_603901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_603966 = ref object of OpenApiRestCall_602433
proc url_PostSetPlatformApplicationAttributes_603968(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetPlatformApplicationAttributes_603967(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603969 = query.getOrDefault("Action")
  valid_603969 = validateParameter(valid_603969, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_603969 != nil:
    section.add "Action", valid_603969
  var valid_603970 = query.getOrDefault("Version")
  valid_603970 = validateParameter(valid_603970, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603970 != nil:
    section.add "Version", valid_603970
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603971 = header.getOrDefault("X-Amz-Date")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Date", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Security-Token")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Security-Token", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Content-Sha256", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Algorithm")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Algorithm", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-Signature")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Signature", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-SignedHeaders", valid_603976
  var valid_603977 = header.getOrDefault("X-Amz-Credential")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Credential", valid_603977
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_603978 = formData.getOrDefault("Attributes.0.value")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "Attributes.0.value", valid_603978
  var valid_603979 = formData.getOrDefault("Attributes.0.key")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "Attributes.0.key", valid_603979
  var valid_603980 = formData.getOrDefault("Attributes.1.key")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "Attributes.1.key", valid_603980
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_603981 = formData.getOrDefault("PlatformApplicationArn")
  valid_603981 = validateParameter(valid_603981, JString, required = true,
                                 default = nil)
  if valid_603981 != nil:
    section.add "PlatformApplicationArn", valid_603981
  var valid_603982 = formData.getOrDefault("Attributes.2.value")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "Attributes.2.value", valid_603982
  var valid_603983 = formData.getOrDefault("Attributes.2.key")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "Attributes.2.key", valid_603983
  var valid_603984 = formData.getOrDefault("Attributes.1.value")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "Attributes.1.value", valid_603984
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603985: Call_PostSetPlatformApplicationAttributes_603966;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_603985.validator(path, query, header, formData, body)
  let scheme = call_603985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603985.url(scheme.get, call_603985.host, call_603985.base,
                         call_603985.route, valid.getOrDefault("path"))
  result = hook(call_603985, url, valid)

proc call*(call_603986: Call_PostSetPlatformApplicationAttributes_603966;
          PlatformApplicationArn: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_603987 = newJObject()
  var formData_603988 = newJObject()
  add(formData_603988, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603988, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603988, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603987, "Action", newJString(Action))
  add(formData_603988, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_603988, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603988, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603987, "Version", newJString(Version))
  add(formData_603988, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603986.call(nil, query_603987, nil, formData_603988, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_603966(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_603967, base: "/",
    url: url_PostSetPlatformApplicationAttributes_603968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_603944 = ref object of OpenApiRestCall_602433
proc url_GetSetPlatformApplicationAttributes_603946(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetPlatformApplicationAttributes_603945(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  section = newJObject()
  var valid_603947 = query.getOrDefault("Attributes.2.key")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "Attributes.2.key", valid_603947
  var valid_603948 = query.getOrDefault("Attributes.1.value")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "Attributes.1.value", valid_603948
  var valid_603949 = query.getOrDefault("Attributes.0.value")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "Attributes.0.value", valid_603949
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603950 = query.getOrDefault("Action")
  valid_603950 = validateParameter(valid_603950, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_603950 != nil:
    section.add "Action", valid_603950
  var valid_603951 = query.getOrDefault("Attributes.1.key")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "Attributes.1.key", valid_603951
  var valid_603952 = query.getOrDefault("Attributes.2.value")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "Attributes.2.value", valid_603952
  var valid_603953 = query.getOrDefault("Attributes.0.key")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "Attributes.0.key", valid_603953
  var valid_603954 = query.getOrDefault("Version")
  valid_603954 = validateParameter(valid_603954, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603954 != nil:
    section.add "Version", valid_603954
  var valid_603955 = query.getOrDefault("PlatformApplicationArn")
  valid_603955 = validateParameter(valid_603955, JString, required = true,
                                 default = nil)
  if valid_603955 != nil:
    section.add "PlatformApplicationArn", valid_603955
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603956 = header.getOrDefault("X-Amz-Date")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Date", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Security-Token")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Security-Token", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Content-Sha256", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Algorithm")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Algorithm", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Signature")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Signature", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-SignedHeaders", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Credential")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Credential", valid_603962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603963: Call_GetSetPlatformApplicationAttributes_603944;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_603963.validator(path, query, header, formData, body)
  let scheme = call_603963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603963.url(scheme.get, call_603963.host, call_603963.base,
                         call_603963.route, valid.getOrDefault("path"))
  result = hook(call_603963, url, valid)

proc call*(call_603964: Call_GetSetPlatformApplicationAttributes_603944;
          PlatformApplicationArn: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes2Key: string
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  var query_603965 = newJObject()
  add(query_603965, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603965, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603965, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603965, "Action", newJString(Action))
  add(query_603965, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603965, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603965, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603965, "Version", newJString(Version))
  add(query_603965, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_603964.call(nil, query_603965, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_603944(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_603945, base: "/",
    url: url_GetSetPlatformApplicationAttributes_603946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_604010 = ref object of OpenApiRestCall_602433
proc url_PostSetSMSAttributes_604012(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSMSAttributes_604011(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604013 = query.getOrDefault("Action")
  valid_604013 = validateParameter(valid_604013, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_604013 != nil:
    section.add "Action", valid_604013
  var valid_604014 = query.getOrDefault("Version")
  valid_604014 = validateParameter(valid_604014, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604014 != nil:
    section.add "Version", valid_604014
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604015 = header.getOrDefault("X-Amz-Date")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Date", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Security-Token")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Security-Token", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Content-Sha256", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Algorithm")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Algorithm", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Signature")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Signature", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-SignedHeaders", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Credential")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Credential", valid_604021
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.2.value: JString
  ##   attributes.2.key: JString
  ##   attributes.1.value: JString
  ##   attributes.1.key: JString
  ##   attributes.0.key: JString
  ##   attributes.0.value: JString
  section = newJObject()
  var valid_604022 = formData.getOrDefault("attributes.2.value")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "attributes.2.value", valid_604022
  var valid_604023 = formData.getOrDefault("attributes.2.key")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "attributes.2.key", valid_604023
  var valid_604024 = formData.getOrDefault("attributes.1.value")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "attributes.1.value", valid_604024
  var valid_604025 = formData.getOrDefault("attributes.1.key")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "attributes.1.key", valid_604025
  var valid_604026 = formData.getOrDefault("attributes.0.key")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "attributes.0.key", valid_604026
  var valid_604027 = formData.getOrDefault("attributes.0.value")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "attributes.0.value", valid_604027
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604028: Call_PostSetSMSAttributes_604010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604028.validator(path, query, header, formData, body)
  let scheme = call_604028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604028.url(scheme.get, call_604028.host, call_604028.base,
                         call_604028.route, valid.getOrDefault("path"))
  result = hook(call_604028, url, valid)

proc call*(call_604029: Call_PostSetSMSAttributes_604010;
          attributes2Value: string = ""; attributes2Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Value: string = "";
          attributes1Key: string = ""; attributes0Key: string = "";
          Version: string = "2010-03-31"; attributes0Value: string = ""): Recallable =
  ## postSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Value: string
  ##   attributes2Key: string
  ##   Action: string (required)
  ##   attributes1Value: string
  ##   attributes1Key: string
  ##   attributes0Key: string
  ##   Version: string (required)
  ##   attributes0Value: string
  var query_604030 = newJObject()
  var formData_604031 = newJObject()
  add(formData_604031, "attributes.2.value", newJString(attributes2Value))
  add(formData_604031, "attributes.2.key", newJString(attributes2Key))
  add(query_604030, "Action", newJString(Action))
  add(formData_604031, "attributes.1.value", newJString(attributes1Value))
  add(formData_604031, "attributes.1.key", newJString(attributes1Key))
  add(formData_604031, "attributes.0.key", newJString(attributes0Key))
  add(query_604030, "Version", newJString(Version))
  add(formData_604031, "attributes.0.value", newJString(attributes0Value))
  result = call_604029.call(nil, query_604030, nil, formData_604031, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_604010(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_604011, base: "/",
    url: url_PostSetSMSAttributes_604012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_603989 = ref object of OpenApiRestCall_602433
proc url_GetSetSMSAttributes_603991(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSMSAttributes_603990(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   attributes.2.key: JString
  ##   attributes.1.key: JString
  ##   Action: JString (required)
  ##   attributes.1.value: JString
  ##   attributes.0.value: JString
  ##   attributes.2.value: JString
  ##   attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_603992 = query.getOrDefault("attributes.2.key")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "attributes.2.key", valid_603992
  var valid_603993 = query.getOrDefault("attributes.1.key")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "attributes.1.key", valid_603993
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603994 = query.getOrDefault("Action")
  valid_603994 = validateParameter(valid_603994, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_603994 != nil:
    section.add "Action", valid_603994
  var valid_603995 = query.getOrDefault("attributes.1.value")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "attributes.1.value", valid_603995
  var valid_603996 = query.getOrDefault("attributes.0.value")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "attributes.0.value", valid_603996
  var valid_603997 = query.getOrDefault("attributes.2.value")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "attributes.2.value", valid_603997
  var valid_603998 = query.getOrDefault("attributes.0.key")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "attributes.0.key", valid_603998
  var valid_603999 = query.getOrDefault("Version")
  valid_603999 = validateParameter(valid_603999, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603999 != nil:
    section.add "Version", valid_603999
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604000 = header.getOrDefault("X-Amz-Date")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Date", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Security-Token")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Security-Token", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Content-Sha256", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Algorithm")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Algorithm", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Signature")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Signature", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-SignedHeaders", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-Credential")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Credential", valid_604006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604007: Call_GetSetSMSAttributes_603989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604007.validator(path, query, header, formData, body)
  let scheme = call_604007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604007.url(scheme.get, call_604007.host, call_604007.base,
                         call_604007.route, valid.getOrDefault("path"))
  result = hook(call_604007, url, valid)

proc call*(call_604008: Call_GetSetSMSAttributes_603989;
          attributes2Key: string = ""; attributes1Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Value: string = "";
          attributes0Value: string = ""; attributes2Value: string = "";
          attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Key: string
  ##   attributes1Key: string
  ##   Action: string (required)
  ##   attributes1Value: string
  ##   attributes0Value: string
  ##   attributes2Value: string
  ##   attributes0Key: string
  ##   Version: string (required)
  var query_604009 = newJObject()
  add(query_604009, "attributes.2.key", newJString(attributes2Key))
  add(query_604009, "attributes.1.key", newJString(attributes1Key))
  add(query_604009, "Action", newJString(Action))
  add(query_604009, "attributes.1.value", newJString(attributes1Value))
  add(query_604009, "attributes.0.value", newJString(attributes0Value))
  add(query_604009, "attributes.2.value", newJString(attributes2Value))
  add(query_604009, "attributes.0.key", newJString(attributes0Key))
  add(query_604009, "Version", newJString(Version))
  result = call_604008.call(nil, query_604009, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_603989(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_603990, base: "/",
    url: url_GetSetSMSAttributes_603991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_604050 = ref object of OpenApiRestCall_602433
proc url_PostSetSubscriptionAttributes_604052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSubscriptionAttributes_604051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604053 = query.getOrDefault("Action")
  valid_604053 = validateParameter(valid_604053, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_604053 != nil:
    section.add "Action", valid_604053
  var valid_604054 = query.getOrDefault("Version")
  valid_604054 = validateParameter(valid_604054, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604054 != nil:
    section.add "Version", valid_604054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604055 = header.getOrDefault("X-Amz-Date")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Date", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-Security-Token")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Security-Token", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Content-Sha256", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Algorithm")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Algorithm", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Signature")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Signature", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-SignedHeaders", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Credential")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Credential", valid_604061
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_604062 = formData.getOrDefault("AttributeName")
  valid_604062 = validateParameter(valid_604062, JString, required = true,
                                 default = nil)
  if valid_604062 != nil:
    section.add "AttributeName", valid_604062
  var valid_604063 = formData.getOrDefault("AttributeValue")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "AttributeValue", valid_604063
  var valid_604064 = formData.getOrDefault("SubscriptionArn")
  valid_604064 = validateParameter(valid_604064, JString, required = true,
                                 default = nil)
  if valid_604064 != nil:
    section.add "SubscriptionArn", valid_604064
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604065: Call_PostSetSubscriptionAttributes_604050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_604065.validator(path, query, header, formData, body)
  let scheme = call_604065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604065.url(scheme.get, call_604065.host, call_604065.base,
                         call_604065.route, valid.getOrDefault("path"))
  result = hook(call_604065, url, valid)

proc call*(call_604066: Call_PostSetSubscriptionAttributes_604050;
          AttributeName: string; SubscriptionArn: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   Version: string (required)
  var query_604067 = newJObject()
  var formData_604068 = newJObject()
  add(formData_604068, "AttributeName", newJString(AttributeName))
  add(formData_604068, "AttributeValue", newJString(AttributeValue))
  add(query_604067, "Action", newJString(Action))
  add(formData_604068, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604067, "Version", newJString(Version))
  result = call_604066.call(nil, query_604067, nil, formData_604068, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_604050(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_604051, base: "/",
    url: url_PostSetSubscriptionAttributes_604052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_604032 = ref object of OpenApiRestCall_602433
proc url_GetSetSubscriptionAttributes_604034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSubscriptionAttributes_604033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_604035 = query.getOrDefault("SubscriptionArn")
  valid_604035 = validateParameter(valid_604035, JString, required = true,
                                 default = nil)
  if valid_604035 != nil:
    section.add "SubscriptionArn", valid_604035
  var valid_604036 = query.getOrDefault("AttributeName")
  valid_604036 = validateParameter(valid_604036, JString, required = true,
                                 default = nil)
  if valid_604036 != nil:
    section.add "AttributeName", valid_604036
  var valid_604037 = query.getOrDefault("Action")
  valid_604037 = validateParameter(valid_604037, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_604037 != nil:
    section.add "Action", valid_604037
  var valid_604038 = query.getOrDefault("AttributeValue")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "AttributeValue", valid_604038
  var valid_604039 = query.getOrDefault("Version")
  valid_604039 = validateParameter(valid_604039, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604039 != nil:
    section.add "Version", valid_604039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604040 = header.getOrDefault("X-Amz-Date")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Date", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Security-Token")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Security-Token", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Content-Sha256", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Algorithm")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Algorithm", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Signature")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Signature", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-SignedHeaders", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Credential")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Credential", valid_604046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604047: Call_GetSetSubscriptionAttributes_604032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_604047.validator(path, query, header, formData, body)
  let scheme = call_604047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604047.url(scheme.get, call_604047.host, call_604047.base,
                         call_604047.route, valid.getOrDefault("path"))
  result = hook(call_604047, url, valid)

proc call*(call_604048: Call_GetSetSubscriptionAttributes_604032;
          SubscriptionArn: string; AttributeName: string;
          Action: string = "SetSubscriptionAttributes"; AttributeValue: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Action: string (required)
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Version: string (required)
  var query_604049 = newJObject()
  add(query_604049, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604049, "AttributeName", newJString(AttributeName))
  add(query_604049, "Action", newJString(Action))
  add(query_604049, "AttributeValue", newJString(AttributeValue))
  add(query_604049, "Version", newJString(Version))
  result = call_604048.call(nil, query_604049, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_604032(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_604033, base: "/",
    url: url_GetSetSubscriptionAttributes_604034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_604087 = ref object of OpenApiRestCall_602433
proc url_PostSetTopicAttributes_604089(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetTopicAttributes_604088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604090 = query.getOrDefault("Action")
  valid_604090 = validateParameter(valid_604090, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_604090 != nil:
    section.add "Action", valid_604090
  var valid_604091 = query.getOrDefault("Version")
  valid_604091 = validateParameter(valid_604091, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604091 != nil:
    section.add "Version", valid_604091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604092 = header.getOrDefault("X-Amz-Date")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Date", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Security-Token")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Security-Token", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Content-Sha256", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Algorithm")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Algorithm", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Signature")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Signature", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-SignedHeaders", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Credential")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Credential", valid_604098
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_604099 = formData.getOrDefault("TopicArn")
  valid_604099 = validateParameter(valid_604099, JString, required = true,
                                 default = nil)
  if valid_604099 != nil:
    section.add "TopicArn", valid_604099
  var valid_604100 = formData.getOrDefault("AttributeName")
  valid_604100 = validateParameter(valid_604100, JString, required = true,
                                 default = nil)
  if valid_604100 != nil:
    section.add "AttributeName", valid_604100
  var valid_604101 = formData.getOrDefault("AttributeValue")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "AttributeValue", valid_604101
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604102: Call_PostSetTopicAttributes_604087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_604102.validator(path, query, header, formData, body)
  let scheme = call_604102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604102.url(scheme.get, call_604102.host, call_604102.base,
                         call_604102.route, valid.getOrDefault("path"))
  result = hook(call_604102, url, valid)

proc call*(call_604103: Call_PostSetTopicAttributes_604087; TopicArn: string;
          AttributeName: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604104 = newJObject()
  var formData_604105 = newJObject()
  add(formData_604105, "TopicArn", newJString(TopicArn))
  add(formData_604105, "AttributeName", newJString(AttributeName))
  add(formData_604105, "AttributeValue", newJString(AttributeValue))
  add(query_604104, "Action", newJString(Action))
  add(query_604104, "Version", newJString(Version))
  result = call_604103.call(nil, query_604104, nil, formData_604105, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_604087(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_604088, base: "/",
    url: url_PostSetTopicAttributes_604089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_604069 = ref object of OpenApiRestCall_602433
proc url_GetSetTopicAttributes_604071(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetTopicAttributes_604070(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AttributeName` field"
  var valid_604072 = query.getOrDefault("AttributeName")
  valid_604072 = validateParameter(valid_604072, JString, required = true,
                                 default = nil)
  if valid_604072 != nil:
    section.add "AttributeName", valid_604072
  var valid_604073 = query.getOrDefault("Action")
  valid_604073 = validateParameter(valid_604073, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_604073 != nil:
    section.add "Action", valid_604073
  var valid_604074 = query.getOrDefault("AttributeValue")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "AttributeValue", valid_604074
  var valid_604075 = query.getOrDefault("TopicArn")
  valid_604075 = validateParameter(valid_604075, JString, required = true,
                                 default = nil)
  if valid_604075 != nil:
    section.add "TopicArn", valid_604075
  var valid_604076 = query.getOrDefault("Version")
  valid_604076 = validateParameter(valid_604076, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604076 != nil:
    section.add "Version", valid_604076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604077 = header.getOrDefault("X-Amz-Date")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Date", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Security-Token")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Security-Token", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Content-Sha256", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Algorithm")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Algorithm", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Signature")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Signature", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-SignedHeaders", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-Credential")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Credential", valid_604083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604084: Call_GetSetTopicAttributes_604069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_604084.validator(path, query, header, formData, body)
  let scheme = call_604084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604084.url(scheme.get, call_604084.host, call_604084.base,
                         call_604084.route, valid.getOrDefault("path"))
  result = hook(call_604084, url, valid)

proc call*(call_604085: Call_GetSetTopicAttributes_604069; AttributeName: string;
          TopicArn: string; Action: string = "SetTopicAttributes";
          AttributeValue: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Action: string (required)
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   Version: string (required)
  var query_604086 = newJObject()
  add(query_604086, "AttributeName", newJString(AttributeName))
  add(query_604086, "Action", newJString(Action))
  add(query_604086, "AttributeValue", newJString(AttributeValue))
  add(query_604086, "TopicArn", newJString(TopicArn))
  add(query_604086, "Version", newJString(Version))
  result = call_604085.call(nil, query_604086, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_604069(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_604070, base: "/",
    url: url_GetSetTopicAttributes_604071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_604131 = ref object of OpenApiRestCall_602433
proc url_PostSubscribe_604133(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSubscribe_604132(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604134 = query.getOrDefault("Action")
  valid_604134 = validateParameter(valid_604134, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_604134 != nil:
    section.add "Action", valid_604134
  var valid_604135 = query.getOrDefault("Version")
  valid_604135 = validateParameter(valid_604135, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604135 != nil:
    section.add "Version", valid_604135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604136 = header.getOrDefault("X-Amz-Date")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Date", valid_604136
  var valid_604137 = header.getOrDefault("X-Amz-Security-Token")
  valid_604137 = validateParameter(valid_604137, JString, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "X-Amz-Security-Token", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Content-Sha256", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Algorithm")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Algorithm", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Signature")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Signature", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-SignedHeaders", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Credential")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Credential", valid_604142
  result.add "header", section
  ## parameters in `formData` object:
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.0.value: JString
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_604143 = formData.getOrDefault("Endpoint")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "Endpoint", valid_604143
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_604144 = formData.getOrDefault("TopicArn")
  valid_604144 = validateParameter(valid_604144, JString, required = true,
                                 default = nil)
  if valid_604144 != nil:
    section.add "TopicArn", valid_604144
  var valid_604145 = formData.getOrDefault("Attributes.0.value")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "Attributes.0.value", valid_604145
  var valid_604146 = formData.getOrDefault("Protocol")
  valid_604146 = validateParameter(valid_604146, JString, required = true,
                                 default = nil)
  if valid_604146 != nil:
    section.add "Protocol", valid_604146
  var valid_604147 = formData.getOrDefault("Attributes.0.key")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "Attributes.0.key", valid_604147
  var valid_604148 = formData.getOrDefault("Attributes.1.key")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "Attributes.1.key", valid_604148
  var valid_604149 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_604149 = validateParameter(valid_604149, JBool, required = false, default = nil)
  if valid_604149 != nil:
    section.add "ReturnSubscriptionArn", valid_604149
  var valid_604150 = formData.getOrDefault("Attributes.2.value")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "Attributes.2.value", valid_604150
  var valid_604151 = formData.getOrDefault("Attributes.2.key")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "Attributes.2.key", valid_604151
  var valid_604152 = formData.getOrDefault("Attributes.1.value")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "Attributes.1.value", valid_604152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604153: Call_PostSubscribe_604131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604153.validator(path, query, header, formData, body)
  let scheme = call_604153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604153.url(scheme.get, call_604153.host, call_604153.base,
                         call_604153.route, valid.getOrDefault("path"))
  result = hook(call_604153, url, valid)

proc call*(call_604154: Call_PostSubscribe_604131; TopicArn: string;
          Protocol: string; Endpoint: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          ReturnSubscriptionArn: bool = false; Action: string = "Subscribe";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes0Value: string
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_604155 = newJObject()
  var formData_604156 = newJObject()
  add(formData_604156, "Endpoint", newJString(Endpoint))
  add(formData_604156, "TopicArn", newJString(TopicArn))
  add(formData_604156, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_604156, "Protocol", newJString(Protocol))
  add(formData_604156, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_604156, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_604156, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_604155, "Action", newJString(Action))
  add(formData_604156, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_604156, "Attributes.2.key", newJString(Attributes2Key))
  add(query_604155, "Version", newJString(Version))
  add(formData_604156, "Attributes.1.value", newJString(Attributes1Value))
  result = call_604154.call(nil, query_604155, nil, formData_604156, nil)

var postSubscribe* = Call_PostSubscribe_604131(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_604132,
    base: "/", url: url_PostSubscribe_604133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_604106 = ref object of OpenApiRestCall_602433
proc url_GetSubscribe_604108(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSubscribe_604107(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.1.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_604109 = query.getOrDefault("Attributes.2.key")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "Attributes.2.key", valid_604109
  var valid_604110 = query.getOrDefault("Endpoint")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "Endpoint", valid_604110
  assert query != nil,
        "query argument is necessary due to required `Protocol` field"
  var valid_604111 = query.getOrDefault("Protocol")
  valid_604111 = validateParameter(valid_604111, JString, required = true,
                                 default = nil)
  if valid_604111 != nil:
    section.add "Protocol", valid_604111
  var valid_604112 = query.getOrDefault("Attributes.1.value")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "Attributes.1.value", valid_604112
  var valid_604113 = query.getOrDefault("Attributes.0.value")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "Attributes.0.value", valid_604113
  var valid_604114 = query.getOrDefault("Action")
  valid_604114 = validateParameter(valid_604114, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_604114 != nil:
    section.add "Action", valid_604114
  var valid_604115 = query.getOrDefault("ReturnSubscriptionArn")
  valid_604115 = validateParameter(valid_604115, JBool, required = false, default = nil)
  if valid_604115 != nil:
    section.add "ReturnSubscriptionArn", valid_604115
  var valid_604116 = query.getOrDefault("Attributes.1.key")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "Attributes.1.key", valid_604116
  var valid_604117 = query.getOrDefault("TopicArn")
  valid_604117 = validateParameter(valid_604117, JString, required = true,
                                 default = nil)
  if valid_604117 != nil:
    section.add "TopicArn", valid_604117
  var valid_604118 = query.getOrDefault("Attributes.2.value")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "Attributes.2.value", valid_604118
  var valid_604119 = query.getOrDefault("Attributes.0.key")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "Attributes.0.key", valid_604119
  var valid_604120 = query.getOrDefault("Version")
  valid_604120 = validateParameter(valid_604120, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604120 != nil:
    section.add "Version", valid_604120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604121 = header.getOrDefault("X-Amz-Date")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Date", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Security-Token")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Security-Token", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Content-Sha256", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Algorithm")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Algorithm", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Signature")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Signature", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-SignedHeaders", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Credential")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Credential", valid_604127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604128: Call_GetSubscribe_604106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604128.validator(path, query, header, formData, body)
  let scheme = call_604128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604128.url(scheme.get, call_604128.host, call_604128.base,
                         call_604128.route, valid.getOrDefault("path"))
  result = hook(call_604128, url, valid)

proc call*(call_604129: Call_GetSubscribe_604106; Protocol: string; TopicArn: string;
          Attributes2Key: string = ""; Endpoint: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "Subscribe"; ReturnSubscriptionArn: bool = false;
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Attributes2Key: string
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes1Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_604130 = newJObject()
  add(query_604130, "Attributes.2.key", newJString(Attributes2Key))
  add(query_604130, "Endpoint", newJString(Endpoint))
  add(query_604130, "Protocol", newJString(Protocol))
  add(query_604130, "Attributes.1.value", newJString(Attributes1Value))
  add(query_604130, "Attributes.0.value", newJString(Attributes0Value))
  add(query_604130, "Action", newJString(Action))
  add(query_604130, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_604130, "Attributes.1.key", newJString(Attributes1Key))
  add(query_604130, "TopicArn", newJString(TopicArn))
  add(query_604130, "Attributes.2.value", newJString(Attributes2Value))
  add(query_604130, "Attributes.0.key", newJString(Attributes0Key))
  add(query_604130, "Version", newJString(Version))
  result = call_604129.call(nil, query_604130, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_604106(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_604107, base: "/",
    url: url_GetSubscribe_604108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_604174 = ref object of OpenApiRestCall_602433
proc url_PostTagResource_604176(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostTagResource_604175(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604177 = query.getOrDefault("Action")
  valid_604177 = validateParameter(valid_604177, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_604177 != nil:
    section.add "Action", valid_604177
  var valid_604178 = query.getOrDefault("Version")
  valid_604178 = validateParameter(valid_604178, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604178 != nil:
    section.add "Version", valid_604178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604179 = header.getOrDefault("X-Amz-Date")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Date", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Security-Token")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Security-Token", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Content-Sha256", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Algorithm")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Algorithm", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Signature")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Signature", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-SignedHeaders", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-Credential")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Credential", valid_604185
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_604186 = formData.getOrDefault("Tags")
  valid_604186 = validateParameter(valid_604186, JArray, required = true, default = nil)
  if valid_604186 != nil:
    section.add "Tags", valid_604186
  var valid_604187 = formData.getOrDefault("ResourceArn")
  valid_604187 = validateParameter(valid_604187, JString, required = true,
                                 default = nil)
  if valid_604187 != nil:
    section.add "ResourceArn", valid_604187
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604188: Call_PostTagResource_604174; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604188.validator(path, query, header, formData, body)
  let scheme = call_604188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604188.url(scheme.get, call_604188.host, call_604188.base,
                         call_604188.route, valid.getOrDefault("path"))
  result = hook(call_604188, url, valid)

proc call*(call_604189: Call_PostTagResource_604174; Tags: JsonNode;
          ResourceArn: string; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Version: string (required)
  var query_604190 = newJObject()
  var formData_604191 = newJObject()
  if Tags != nil:
    formData_604191.add "Tags", Tags
  add(query_604190, "Action", newJString(Action))
  add(formData_604191, "ResourceArn", newJString(ResourceArn))
  add(query_604190, "Version", newJString(Version))
  result = call_604189.call(nil, query_604190, nil, formData_604191, nil)

var postTagResource* = Call_PostTagResource_604174(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_604175,
    base: "/", url: url_PostTagResource_604176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_604157 = ref object of OpenApiRestCall_602433
proc url_GetTagResource_604159(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTagResource_604158(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_604160 = query.getOrDefault("ResourceArn")
  valid_604160 = validateParameter(valid_604160, JString, required = true,
                                 default = nil)
  if valid_604160 != nil:
    section.add "ResourceArn", valid_604160
  var valid_604161 = query.getOrDefault("Tags")
  valid_604161 = validateParameter(valid_604161, JArray, required = true, default = nil)
  if valid_604161 != nil:
    section.add "Tags", valid_604161
  var valid_604162 = query.getOrDefault("Action")
  valid_604162 = validateParameter(valid_604162, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_604162 != nil:
    section.add "Action", valid_604162
  var valid_604163 = query.getOrDefault("Version")
  valid_604163 = validateParameter(valid_604163, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604163 != nil:
    section.add "Version", valid_604163
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604164 = header.getOrDefault("X-Amz-Date")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Date", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Security-Token")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Security-Token", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Content-Sha256", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-Algorithm")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Algorithm", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Signature")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Signature", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-SignedHeaders", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Credential")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Credential", valid_604170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604171: Call_GetTagResource_604157; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_604171.validator(path, query, header, formData, body)
  let scheme = call_604171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604171.url(scheme.get, call_604171.host, call_604171.base,
                         call_604171.route, valid.getOrDefault("path"))
  result = hook(call_604171, url, valid)

proc call*(call_604172: Call_GetTagResource_604157; ResourceArn: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604173 = newJObject()
  add(query_604173, "ResourceArn", newJString(ResourceArn))
  if Tags != nil:
    query_604173.add "Tags", Tags
  add(query_604173, "Action", newJString(Action))
  add(query_604173, "Version", newJString(Version))
  result = call_604172.call(nil, query_604173, nil, nil, nil)

var getTagResource* = Call_GetTagResource_604157(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_604158,
    base: "/", url: url_GetTagResource_604159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_604208 = ref object of OpenApiRestCall_602433
proc url_PostUnsubscribe_604210(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUnsubscribe_604209(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604211 = query.getOrDefault("Action")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_604211 != nil:
    section.add "Action", valid_604211
  var valid_604212 = query.getOrDefault("Version")
  valid_604212 = validateParameter(valid_604212, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604212 != nil:
    section.add "Version", valid_604212
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604213 = header.getOrDefault("X-Amz-Date")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Date", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Security-Token")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Security-Token", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Content-Sha256", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Algorithm")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Algorithm", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Signature")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Signature", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-SignedHeaders", valid_604218
  var valid_604219 = header.getOrDefault("X-Amz-Credential")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "X-Amz-Credential", valid_604219
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_604220 = formData.getOrDefault("SubscriptionArn")
  valid_604220 = validateParameter(valid_604220, JString, required = true,
                                 default = nil)
  if valid_604220 != nil:
    section.add "SubscriptionArn", valid_604220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604221: Call_PostUnsubscribe_604208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604221.validator(path, query, header, formData, body)
  let scheme = call_604221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604221.url(scheme.get, call_604221.host, call_604221.base,
                         call_604221.route, valid.getOrDefault("path"))
  result = hook(call_604221, url, valid)

proc call*(call_604222: Call_PostUnsubscribe_604208; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Version: string (required)
  var query_604223 = newJObject()
  var formData_604224 = newJObject()
  add(query_604223, "Action", newJString(Action))
  add(formData_604224, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604223, "Version", newJString(Version))
  result = call_604222.call(nil, query_604223, nil, formData_604224, nil)

var postUnsubscribe* = Call_PostUnsubscribe_604208(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_604209,
    base: "/", url: url_PostUnsubscribe_604210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_604192 = ref object of OpenApiRestCall_602433
proc url_GetUnsubscribe_604194(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUnsubscribe_604193(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_604195 = query.getOrDefault("SubscriptionArn")
  valid_604195 = validateParameter(valid_604195, JString, required = true,
                                 default = nil)
  if valid_604195 != nil:
    section.add "SubscriptionArn", valid_604195
  var valid_604196 = query.getOrDefault("Action")
  valid_604196 = validateParameter(valid_604196, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_604196 != nil:
    section.add "Action", valid_604196
  var valid_604197 = query.getOrDefault("Version")
  valid_604197 = validateParameter(valid_604197, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604197 != nil:
    section.add "Version", valid_604197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604198 = header.getOrDefault("X-Amz-Date")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Date", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Security-Token")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Security-Token", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Content-Sha256", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Algorithm")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Algorithm", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-Signature")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Signature", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-SignedHeaders", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Credential")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Credential", valid_604204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604205: Call_GetUnsubscribe_604192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_604205.validator(path, query, header, formData, body)
  let scheme = call_604205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604205.url(scheme.get, call_604205.host, call_604205.base,
                         call_604205.route, valid.getOrDefault("path"))
  result = hook(call_604205, url, valid)

proc call*(call_604206: Call_GetUnsubscribe_604192; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604207 = newJObject()
  add(query_604207, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_604207, "Action", newJString(Action))
  add(query_604207, "Version", newJString(Version))
  result = call_604206.call(nil, query_604207, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_604192(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_604193,
    base: "/", url: url_GetUnsubscribe_604194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_604242 = ref object of OpenApiRestCall_602433
proc url_PostUntagResource_604244(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUntagResource_604243(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604245 = query.getOrDefault("Action")
  valid_604245 = validateParameter(valid_604245, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_604245 != nil:
    section.add "Action", valid_604245
  var valid_604246 = query.getOrDefault("Version")
  valid_604246 = validateParameter(valid_604246, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604246 != nil:
    section.add "Version", valid_604246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604247 = header.getOrDefault("X-Amz-Date")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Date", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Security-Token")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Security-Token", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Content-Sha256", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Algorithm")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Algorithm", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-Signature")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-Signature", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-SignedHeaders", valid_604252
  var valid_604253 = header.getOrDefault("X-Amz-Credential")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Credential", valid_604253
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604254 = formData.getOrDefault("TagKeys")
  valid_604254 = validateParameter(valid_604254, JArray, required = true, default = nil)
  if valid_604254 != nil:
    section.add "TagKeys", valid_604254
  var valid_604255 = formData.getOrDefault("ResourceArn")
  valid_604255 = validateParameter(valid_604255, JString, required = true,
                                 default = nil)
  if valid_604255 != nil:
    section.add "ResourceArn", valid_604255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604256: Call_PostUntagResource_604242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_604256.validator(path, query, header, formData, body)
  let scheme = call_604256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604256.url(scheme.get, call_604256.host, call_604256.base,
                         call_604256.route, valid.getOrDefault("path"))
  result = hook(call_604256, url, valid)

proc call*(call_604257: Call_PostUntagResource_604242; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Version: string (required)
  var query_604258 = newJObject()
  var formData_604259 = newJObject()
  add(query_604258, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604259.add "TagKeys", TagKeys
  add(formData_604259, "ResourceArn", newJString(ResourceArn))
  add(query_604258, "Version", newJString(Version))
  result = call_604257.call(nil, query_604258, nil, formData_604259, nil)

var postUntagResource* = Call_PostUntagResource_604242(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_604243,
    base: "/", url: url_PostUntagResource_604244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_604225 = ref object of OpenApiRestCall_602433
proc url_GetUntagResource_604227(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUntagResource_604226(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_604228 = query.getOrDefault("ResourceArn")
  valid_604228 = validateParameter(valid_604228, JString, required = true,
                                 default = nil)
  if valid_604228 != nil:
    section.add "ResourceArn", valid_604228
  var valid_604229 = query.getOrDefault("Action")
  valid_604229 = validateParameter(valid_604229, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_604229 != nil:
    section.add "Action", valid_604229
  var valid_604230 = query.getOrDefault("TagKeys")
  valid_604230 = validateParameter(valid_604230, JArray, required = true, default = nil)
  if valid_604230 != nil:
    section.add "TagKeys", valid_604230
  var valid_604231 = query.getOrDefault("Version")
  valid_604231 = validateParameter(valid_604231, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_604231 != nil:
    section.add "Version", valid_604231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604232 = header.getOrDefault("X-Amz-Date")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Date", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Security-Token")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Security-Token", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Content-Sha256", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Algorithm")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Algorithm", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-Signature")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-Signature", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-SignedHeaders", valid_604237
  var valid_604238 = header.getOrDefault("X-Amz-Credential")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Credential", valid_604238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604239: Call_GetUntagResource_604225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_604239.validator(path, query, header, formData, body)
  let scheme = call_604239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604239.url(scheme.get, call_604239.host, call_604239.base,
                         call_604239.route, valid.getOrDefault("path"))
  result = hook(call_604239, url, valid)

proc call*(call_604240: Call_GetUntagResource_604225; ResourceArn: string;
          TagKeys: JsonNode; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   Version: string (required)
  var query_604241 = newJObject()
  add(query_604241, "ResourceArn", newJString(ResourceArn))
  add(query_604241, "Action", newJString(Action))
  if TagKeys != nil:
    query_604241.add "TagKeys", TagKeys
  add(query_604241, "Version", newJString(Version))
  result = call_604240.call(nil, query_604241, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_604225(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_604226,
    base: "/", url: url_GetUntagResource_604227,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

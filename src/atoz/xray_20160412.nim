
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS X-Ray
## version: 2016-04-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS X-Ray provides APIs for managing debug traces and retrieving service maps and other data created by processing those traces.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/xray/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "xray.ap-northeast-1.amazonaws.com", "ap-southeast-1": "xray.ap-southeast-1.amazonaws.com",
                           "us-west-2": "xray.us-west-2.amazonaws.com",
                           "eu-west-2": "xray.eu-west-2.amazonaws.com", "ap-northeast-3": "xray.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "xray.eu-central-1.amazonaws.com",
                           "us-east-2": "xray.us-east-2.amazonaws.com",
                           "us-east-1": "xray.us-east-1.amazonaws.com", "cn-northwest-1": "xray.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "xray.ap-south-1.amazonaws.com",
                           "eu-north-1": "xray.eu-north-1.amazonaws.com", "ap-northeast-2": "xray.ap-northeast-2.amazonaws.com",
                           "us-west-1": "xray.us-west-1.amazonaws.com",
                           "us-gov-east-1": "xray.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "xray.eu-west-3.amazonaws.com",
                           "cn-north-1": "xray.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "xray.sa-east-1.amazonaws.com",
                           "eu-west-1": "xray.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "xray.us-gov-west-1.amazonaws.com", "ap-southeast-2": "xray.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "xray.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "xray.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "xray.ap-southeast-1.amazonaws.com",
      "us-west-2": "xray.us-west-2.amazonaws.com",
      "eu-west-2": "xray.eu-west-2.amazonaws.com",
      "ap-northeast-3": "xray.ap-northeast-3.amazonaws.com",
      "eu-central-1": "xray.eu-central-1.amazonaws.com",
      "us-east-2": "xray.us-east-2.amazonaws.com",
      "us-east-1": "xray.us-east-1.amazonaws.com",
      "cn-northwest-1": "xray.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "xray.ap-south-1.amazonaws.com",
      "eu-north-1": "xray.eu-north-1.amazonaws.com",
      "ap-northeast-2": "xray.ap-northeast-2.amazonaws.com",
      "us-west-1": "xray.us-west-1.amazonaws.com",
      "us-gov-east-1": "xray.us-gov-east-1.amazonaws.com",
      "eu-west-3": "xray.eu-west-3.amazonaws.com",
      "cn-north-1": "xray.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "xray.sa-east-1.amazonaws.com",
      "eu-west-1": "xray.eu-west-1.amazonaws.com",
      "us-gov-west-1": "xray.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "xray.ap-southeast-2.amazonaws.com",
      "ca-central-1": "xray.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "xray"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetTraces_602770 = ref object of OpenApiRestCall_602433
proc url_BatchGetTraces_602772(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetTraces_602771(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602884 = query.getOrDefault("NextToken")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "NextToken", valid_602884
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
  var valid_602885 = header.getOrDefault("X-Amz-Date")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Date", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Security-Token")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Security-Token", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Content-Sha256", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Signature")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Signature", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-SignedHeaders", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Credential")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Credential", valid_602891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602915: Call_BatchGetTraces_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
  ## 
  let valid = call_602915.validator(path, query, header, formData, body)
  let scheme = call_602915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602915.url(scheme.get, call_602915.host, call_602915.base,
                         call_602915.route, valid.getOrDefault("path"))
  result = hook(call_602915, url, valid)

proc call*(call_602986: Call_BatchGetTraces_602770; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## batchGetTraces
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602987 = newJObject()
  var body_602989 = newJObject()
  add(query_602987, "NextToken", newJString(NextToken))
  if body != nil:
    body_602989 = body
  result = call_602986.call(nil, query_602987, nil, nil, body_602989)

var batchGetTraces* = Call_BatchGetTraces_602770(name: "batchGetTraces",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/Traces",
    validator: validate_BatchGetTraces_602771, base: "/", url: url_BatchGetTraces_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_603028 = ref object of OpenApiRestCall_602433
proc url_CreateGroup_603030(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGroup_603029(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a group resource with a name and a filter expression. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603031 = header.getOrDefault("X-Amz-Date")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Date", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Security-Token")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Security-Token", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Content-Sha256", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Algorithm")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Algorithm", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Signature")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Signature", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-SignedHeaders", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Credential")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Credential", valid_603037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603039: Call_CreateGroup_603028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group resource with a name and a filter expression. 
  ## 
  let valid = call_603039.validator(path, query, header, formData, body)
  let scheme = call_603039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603039.url(scheme.get, call_603039.host, call_603039.base,
                         call_603039.route, valid.getOrDefault("path"))
  result = hook(call_603039, url, valid)

proc call*(call_603040: Call_CreateGroup_603028; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group resource with a name and a filter expression. 
  ##   body: JObject (required)
  var body_603041 = newJObject()
  if body != nil:
    body_603041 = body
  result = call_603040.call(nil, nil, nil, nil, body_603041)

var createGroup* = Call_CreateGroup_603028(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "xray.amazonaws.com",
                                        route: "/CreateGroup",
                                        validator: validate_CreateGroup_603029,
                                        base: "/", url: url_CreateGroup_603030,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSamplingRule_603042 = ref object of OpenApiRestCall_602433
proc url_CreateSamplingRule_603044(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSamplingRule_603043(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603045 = header.getOrDefault("X-Amz-Date")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Date", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Security-Token")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Security-Token", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Content-Sha256", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Algorithm")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Algorithm", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Signature")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Signature", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-SignedHeaders", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Credential")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Credential", valid_603051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603053: Call_CreateSamplingRule_603042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
  ## 
  let valid = call_603053.validator(path, query, header, formData, body)
  let scheme = call_603053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603053.url(scheme.get, call_603053.host, call_603053.base,
                         call_603053.route, valid.getOrDefault("path"))
  result = hook(call_603053, url, valid)

proc call*(call_603054: Call_CreateSamplingRule_603042; body: JsonNode): Recallable =
  ## createSamplingRule
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
  ##   body: JObject (required)
  var body_603055 = newJObject()
  if body != nil:
    body_603055 = body
  result = call_603054.call(nil, nil, nil, nil, body_603055)

var createSamplingRule* = Call_CreateSamplingRule_603042(
    name: "createSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/CreateSamplingRule",
    validator: validate_CreateSamplingRule_603043, base: "/",
    url: url_CreateSamplingRule_603044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_603056 = ref object of OpenApiRestCall_602433
proc url_DeleteGroup_603058(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteGroup_603057(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a group resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603059 = header.getOrDefault("X-Amz-Date")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Date", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Security-Token")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Security-Token", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Content-Sha256", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Algorithm")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Algorithm", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Signature")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Signature", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-SignedHeaders", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Credential")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Credential", valid_603065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603067: Call_DeleteGroup_603056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group resource.
  ## 
  let valid = call_603067.validator(path, query, header, formData, body)
  let scheme = call_603067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603067.url(scheme.get, call_603067.host, call_603067.base,
                         call_603067.route, valid.getOrDefault("path"))
  result = hook(call_603067, url, valid)

proc call*(call_603068: Call_DeleteGroup_603056; body: JsonNode): Recallable =
  ## deleteGroup
  ## Deletes a group resource.
  ##   body: JObject (required)
  var body_603069 = newJObject()
  if body != nil:
    body_603069 = body
  result = call_603068.call(nil, nil, nil, nil, body_603069)

var deleteGroup* = Call_DeleteGroup_603056(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "xray.amazonaws.com",
                                        route: "/DeleteGroup",
                                        validator: validate_DeleteGroup_603057,
                                        base: "/", url: url_DeleteGroup_603058,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSamplingRule_603070 = ref object of OpenApiRestCall_602433
proc url_DeleteSamplingRule_603072(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSamplingRule_603071(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a sampling rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603073 = header.getOrDefault("X-Amz-Date")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Date", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Security-Token")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Security-Token", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_DeleteSamplingRule_603070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a sampling rule.
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_DeleteSamplingRule_603070; body: JsonNode): Recallable =
  ## deleteSamplingRule
  ## Deletes a sampling rule.
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var deleteSamplingRule* = Call_DeleteSamplingRule_603070(
    name: "deleteSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/DeleteSamplingRule",
    validator: validate_DeleteSamplingRule_603071, base: "/",
    url: url_DeleteSamplingRule_603072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEncryptionConfig_603084 = ref object of OpenApiRestCall_602433
proc url_GetEncryptionConfig_603086(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetEncryptionConfig_603085(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the current encryption configuration for X-Ray data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Content-Sha256", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Algorithm")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Algorithm", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Signature")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Signature", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-SignedHeaders", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Credential")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Credential", valid_603093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_GetEncryptionConfig_603084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current encryption configuration for X-Ray data.
  ## 
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"))
  result = hook(call_603094, url, valid)

proc call*(call_603095: Call_GetEncryptionConfig_603084): Recallable =
  ## getEncryptionConfig
  ## Retrieves the current encryption configuration for X-Ray data.
  result = call_603095.call(nil, nil, nil, nil, nil)

var getEncryptionConfig* = Call_GetEncryptionConfig_603084(
    name: "getEncryptionConfig", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/EncryptionConfig",
    validator: validate_GetEncryptionConfig_603085, base: "/",
    url: url_GetEncryptionConfig_603086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_603096 = ref object of OpenApiRestCall_602433
proc url_GetGroup_603098(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGroup_603097(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves group resource details.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603099 = header.getOrDefault("X-Amz-Date")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Date", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Security-Token")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Security-Token", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Content-Sha256", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Algorithm")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Algorithm", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Signature")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Signature", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Credential")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Credential", valid_603105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603107: Call_GetGroup_603096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves group resource details.
  ## 
  let valid = call_603107.validator(path, query, header, formData, body)
  let scheme = call_603107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603107.url(scheme.get, call_603107.host, call_603107.base,
                         call_603107.route, valid.getOrDefault("path"))
  result = hook(call_603107, url, valid)

proc call*(call_603108: Call_GetGroup_603096; body: JsonNode): Recallable =
  ## getGroup
  ## Retrieves group resource details.
  ##   body: JObject (required)
  var body_603109 = newJObject()
  if body != nil:
    body_603109 = body
  result = call_603108.call(nil, nil, nil, nil, body_603109)

var getGroup* = Call_GetGroup_603096(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "xray.amazonaws.com", route: "/GetGroup",
                                  validator: validate_GetGroup_603097, base: "/",
                                  url: url_GetGroup_603098,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroups_603110 = ref object of OpenApiRestCall_602433
proc url_GetGroups_603112(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGroups_603111(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all active group details.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603113 = query.getOrDefault("NextToken")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "NextToken", valid_603113
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
  var valid_603114 = header.getOrDefault("X-Amz-Date")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Date", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Security-Token")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Security-Token", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Content-Sha256", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Algorithm")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Algorithm", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Signature")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Signature", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-SignedHeaders", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Credential")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Credential", valid_603120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603122: Call_GetGroups_603110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all active group details.
  ## 
  let valid = call_603122.validator(path, query, header, formData, body)
  let scheme = call_603122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603122.url(scheme.get, call_603122.host, call_603122.base,
                         call_603122.route, valid.getOrDefault("path"))
  result = hook(call_603122, url, valid)

proc call*(call_603123: Call_GetGroups_603110; body: JsonNode; NextToken: string = ""): Recallable =
  ## getGroups
  ## Retrieves all active group details.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603124 = newJObject()
  var body_603125 = newJObject()
  add(query_603124, "NextToken", newJString(NextToken))
  if body != nil:
    body_603125 = body
  result = call_603123.call(nil, query_603124, nil, nil, body_603125)

var getGroups* = Call_GetGroups_603110(name: "getGroups", meth: HttpMethod.HttpPost,
                                    host: "xray.amazonaws.com", route: "/Groups",
                                    validator: validate_GetGroups_603111,
                                    base: "/", url: url_GetGroups_603112,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingRules_603126 = ref object of OpenApiRestCall_602433
proc url_GetSamplingRules_603128(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSamplingRules_603127(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves all sampling rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603129 = query.getOrDefault("NextToken")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "NextToken", valid_603129
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
  var valid_603130 = header.getOrDefault("X-Amz-Date")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Date", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Security-Token")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Security-Token", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Content-Sha256", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Algorithm")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Algorithm", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Signature")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Signature", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-SignedHeaders", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Credential")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Credential", valid_603136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603138: Call_GetSamplingRules_603126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all sampling rules.
  ## 
  let valid = call_603138.validator(path, query, header, formData, body)
  let scheme = call_603138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603138.url(scheme.get, call_603138.host, call_603138.base,
                         call_603138.route, valid.getOrDefault("path"))
  result = hook(call_603138, url, valid)

proc call*(call_603139: Call_GetSamplingRules_603126; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getSamplingRules
  ## Retrieves all sampling rules.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603140 = newJObject()
  var body_603141 = newJObject()
  add(query_603140, "NextToken", newJString(NextToken))
  if body != nil:
    body_603141 = body
  result = call_603139.call(nil, query_603140, nil, nil, body_603141)

var getSamplingRules* = Call_GetSamplingRules_603126(name: "getSamplingRules",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com",
    route: "/GetSamplingRules", validator: validate_GetSamplingRules_603127,
    base: "/", url: url_GetSamplingRules_603128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingStatisticSummaries_603142 = ref object of OpenApiRestCall_602433
proc url_GetSamplingStatisticSummaries_603144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSamplingStatisticSummaries_603143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about recent sampling results for all sampling rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603145 = query.getOrDefault("NextToken")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "NextToken", valid_603145
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
  var valid_603146 = header.getOrDefault("X-Amz-Date")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Date", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Security-Token")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Security-Token", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Content-Sha256", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Algorithm")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Algorithm", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Signature")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Signature", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-SignedHeaders", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Credential")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Credential", valid_603152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603154: Call_GetSamplingStatisticSummaries_603142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about recent sampling results for all sampling rules.
  ## 
  let valid = call_603154.validator(path, query, header, formData, body)
  let scheme = call_603154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603154.url(scheme.get, call_603154.host, call_603154.base,
                         call_603154.route, valid.getOrDefault("path"))
  result = hook(call_603154, url, valid)

proc call*(call_603155: Call_GetSamplingStatisticSummaries_603142; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getSamplingStatisticSummaries
  ## Retrieves information about recent sampling results for all sampling rules.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603156 = newJObject()
  var body_603157 = newJObject()
  add(query_603156, "NextToken", newJString(NextToken))
  if body != nil:
    body_603157 = body
  result = call_603155.call(nil, query_603156, nil, nil, body_603157)

var getSamplingStatisticSummaries* = Call_GetSamplingStatisticSummaries_603142(
    name: "getSamplingStatisticSummaries", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/SamplingStatisticSummaries",
    validator: validate_GetSamplingStatisticSummaries_603143, base: "/",
    url: url_GetSamplingStatisticSummaries_603144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingTargets_603158 = ref object of OpenApiRestCall_602433
proc url_GetSamplingTargets_603160(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSamplingTargets_603159(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Requests a sampling quota for rules that the service is using to sample requests. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603161 = header.getOrDefault("X-Amz-Date")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Date", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Security-Token")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Security-Token", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Content-Sha256", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Algorithm")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Algorithm", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Signature")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Signature", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-SignedHeaders", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Credential")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Credential", valid_603167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603169: Call_GetSamplingTargets_603158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Requests a sampling quota for rules that the service is using to sample requests. 
  ## 
  let valid = call_603169.validator(path, query, header, formData, body)
  let scheme = call_603169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603169.url(scheme.get, call_603169.host, call_603169.base,
                         call_603169.route, valid.getOrDefault("path"))
  result = hook(call_603169, url, valid)

proc call*(call_603170: Call_GetSamplingTargets_603158; body: JsonNode): Recallable =
  ## getSamplingTargets
  ## Requests a sampling quota for rules that the service is using to sample requests. 
  ##   body: JObject (required)
  var body_603171 = newJObject()
  if body != nil:
    body_603171 = body
  result = call_603170.call(nil, nil, nil, nil, body_603171)

var getSamplingTargets* = Call_GetSamplingTargets_603158(
    name: "getSamplingTargets", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/SamplingTargets",
    validator: validate_GetSamplingTargets_603159, base: "/",
    url: url_GetSamplingTargets_603160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceGraph_603172 = ref object of OpenApiRestCall_602433
proc url_GetServiceGraph_603174(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServiceGraph_603173(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the AWS X-Ray SDK. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603175 = query.getOrDefault("NextToken")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "NextToken", valid_603175
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
  var valid_603176 = header.getOrDefault("X-Amz-Date")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Date", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Security-Token")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Security-Token", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Content-Sha256", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Algorithm")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Algorithm", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Signature")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Signature", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-SignedHeaders", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Credential")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Credential", valid_603182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603184: Call_GetServiceGraph_603172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the AWS X-Ray SDK. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
  ## 
  let valid = call_603184.validator(path, query, header, formData, body)
  let scheme = call_603184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603184.url(scheme.get, call_603184.host, call_603184.base,
                         call_603184.route, valid.getOrDefault("path"))
  result = hook(call_603184, url, valid)

proc call*(call_603185: Call_GetServiceGraph_603172; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getServiceGraph
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the AWS X-Ray SDK. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603186 = newJObject()
  var body_603187 = newJObject()
  add(query_603186, "NextToken", newJString(NextToken))
  if body != nil:
    body_603187 = body
  result = call_603185.call(nil, query_603186, nil, nil, body_603187)

var getServiceGraph* = Call_GetServiceGraph_603172(name: "getServiceGraph",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/ServiceGraph",
    validator: validate_GetServiceGraph_603173, base: "/", url: url_GetServiceGraph_603174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTimeSeriesServiceStatistics_603188 = ref object of OpenApiRestCall_602433
proc url_GetTimeSeriesServiceStatistics_603190(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTimeSeriesServiceStatistics_603189(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get an aggregation of service statistics defined by a specific time range.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603191 = query.getOrDefault("NextToken")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "NextToken", valid_603191
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Content-Sha256", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Algorithm")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Algorithm", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Signature")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Signature", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-SignedHeaders", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Credential")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Credential", valid_603198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603200: Call_GetTimeSeriesServiceStatistics_603188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get an aggregation of service statistics defined by a specific time range.
  ## 
  let valid = call_603200.validator(path, query, header, formData, body)
  let scheme = call_603200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603200.url(scheme.get, call_603200.host, call_603200.base,
                         call_603200.route, valid.getOrDefault("path"))
  result = hook(call_603200, url, valid)

proc call*(call_603201: Call_GetTimeSeriesServiceStatistics_603188; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getTimeSeriesServiceStatistics
  ## Get an aggregation of service statistics defined by a specific time range.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603202 = newJObject()
  var body_603203 = newJObject()
  add(query_603202, "NextToken", newJString(NextToken))
  if body != nil:
    body_603203 = body
  result = call_603201.call(nil, query_603202, nil, nil, body_603203)

var getTimeSeriesServiceStatistics* = Call_GetTimeSeriesServiceStatistics_603188(
    name: "getTimeSeriesServiceStatistics", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TimeSeriesServiceStatistics",
    validator: validate_GetTimeSeriesServiceStatistics_603189, base: "/",
    url: url_GetTimeSeriesServiceStatistics_603190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTraceGraph_603204 = ref object of OpenApiRestCall_602433
proc url_GetTraceGraph_603206(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTraceGraph_603205(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a service graph for one or more specific trace IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603207 = query.getOrDefault("NextToken")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "NextToken", valid_603207
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
  var valid_603208 = header.getOrDefault("X-Amz-Date")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Date", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Security-Token")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Security-Token", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603216: Call_GetTraceGraph_603204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a service graph for one or more specific trace IDs.
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_GetTraceGraph_603204; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getTraceGraph
  ## Retrieves a service graph for one or more specific trace IDs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603218 = newJObject()
  var body_603219 = newJObject()
  add(query_603218, "NextToken", newJString(NextToken))
  if body != nil:
    body_603219 = body
  result = call_603217.call(nil, query_603218, nil, nil, body_603219)

var getTraceGraph* = Call_GetTraceGraph_603204(name: "getTraceGraph",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/TraceGraph",
    validator: validate_GetTraceGraph_603205, base: "/", url: url_GetTraceGraph_603206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTraceSummaries_603220 = ref object of OpenApiRestCall_602433
proc url_GetTraceSummaries_603222(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTraceSummaries_603221(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves IDs and metadata for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603223 = query.getOrDefault("NextToken")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "NextToken", valid_603223
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
  var valid_603224 = header.getOrDefault("X-Amz-Date")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Date", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Security-Token")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Security-Token", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Content-Sha256", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Algorithm")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Algorithm", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Signature")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Signature", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-SignedHeaders", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Credential")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Credential", valid_603230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603232: Call_GetTraceSummaries_603220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves IDs and metadata for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
  ## 
  let valid = call_603232.validator(path, query, header, formData, body)
  let scheme = call_603232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603232.url(scheme.get, call_603232.host, call_603232.base,
                         call_603232.route, valid.getOrDefault("path"))
  result = hook(call_603232, url, valid)

proc call*(call_603233: Call_GetTraceSummaries_603220; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getTraceSummaries
  ## <p>Retrieves IDs and metadata for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603234 = newJObject()
  var body_603235 = newJObject()
  add(query_603234, "NextToken", newJString(NextToken))
  if body != nil:
    body_603235 = body
  result = call_603233.call(nil, query_603234, nil, nil, body_603235)

var getTraceSummaries* = Call_GetTraceSummaries_603220(name: "getTraceSummaries",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/TraceSummaries",
    validator: validate_GetTraceSummaries_603221, base: "/",
    url: url_GetTraceSummaries_603222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEncryptionConfig_603236 = ref object of OpenApiRestCall_602433
proc url_PutEncryptionConfig_603238(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutEncryptionConfig_603237(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the encryption configuration for X-Ray data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Security-Token")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Security-Token", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Content-Sha256", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Algorithm")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Algorithm", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Signature")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Signature", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-SignedHeaders", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Credential")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Credential", valid_603245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603247: Call_PutEncryptionConfig_603236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the encryption configuration for X-Ray data.
  ## 
  let valid = call_603247.validator(path, query, header, formData, body)
  let scheme = call_603247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603247.url(scheme.get, call_603247.host, call_603247.base,
                         call_603247.route, valid.getOrDefault("path"))
  result = hook(call_603247, url, valid)

proc call*(call_603248: Call_PutEncryptionConfig_603236; body: JsonNode): Recallable =
  ## putEncryptionConfig
  ## Updates the encryption configuration for X-Ray data.
  ##   body: JObject (required)
  var body_603249 = newJObject()
  if body != nil:
    body_603249 = body
  result = call_603248.call(nil, nil, nil, nil, body_603249)

var putEncryptionConfig* = Call_PutEncryptionConfig_603236(
    name: "putEncryptionConfig", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/PutEncryptionConfig",
    validator: validate_PutEncryptionConfig_603237, base: "/",
    url: url_PutEncryptionConfig_603238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTelemetryRecords_603250 = ref object of OpenApiRestCall_602433
proc url_PutTelemetryRecords_603252(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutTelemetryRecords_603251(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Used by the AWS X-Ray daemon to upload telemetry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603253 = header.getOrDefault("X-Amz-Date")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Date", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Security-Token")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Security-Token", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_PutTelemetryRecords_603250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by the AWS X-Ray daemon to upload telemetry.
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"))
  result = hook(call_603261, url, valid)

proc call*(call_603262: Call_PutTelemetryRecords_603250; body: JsonNode): Recallable =
  ## putTelemetryRecords
  ## Used by the AWS X-Ray daemon to upload telemetry.
  ##   body: JObject (required)
  var body_603263 = newJObject()
  if body != nil:
    body_603263 = body
  result = call_603262.call(nil, nil, nil, nil, body_603263)

var putTelemetryRecords* = Call_PutTelemetryRecords_603250(
    name: "putTelemetryRecords", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TelemetryRecords",
    validator: validate_PutTelemetryRecords_603251, base: "/",
    url: url_PutTelemetryRecords_603252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTraceSegments_603264 = ref object of OpenApiRestCall_602433
proc url_PutTraceSegments_603266(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutTraceSegments_603265(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Uploads segment documents to AWS X-Ray. The X-Ray SDK generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603267 = header.getOrDefault("X-Amz-Date")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Date", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Content-Sha256", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Algorithm")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Algorithm", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Signature")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Signature", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-SignedHeaders", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Credential")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Credential", valid_603273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603275: Call_PutTraceSegments_603264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads segment documents to AWS X-Ray. The X-Ray SDK generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
  ## 
  let valid = call_603275.validator(path, query, header, formData, body)
  let scheme = call_603275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603275.url(scheme.get, call_603275.host, call_603275.base,
                         call_603275.route, valid.getOrDefault("path"))
  result = hook(call_603275, url, valid)

proc call*(call_603276: Call_PutTraceSegments_603264; body: JsonNode): Recallable =
  ## putTraceSegments
  ## <p>Uploads segment documents to AWS X-Ray. The X-Ray SDK generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603277 = newJObject()
  if body != nil:
    body_603277 = body
  result = call_603276.call(nil, nil, nil, nil, body_603277)

var putTraceSegments* = Call_PutTraceSegments_603264(name: "putTraceSegments",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/TraceSegments",
    validator: validate_PutTraceSegments_603265, base: "/",
    url: url_PutTraceSegments_603266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_603278 = ref object of OpenApiRestCall_602433
proc url_UpdateGroup_603280(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateGroup_603279(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a group resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603281 = header.getOrDefault("X-Amz-Date")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Date", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Security-Token")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Security-Token", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Content-Sha256", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Algorithm")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Algorithm", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Signature")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Signature", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-SignedHeaders", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Credential")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Credential", valid_603287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603289: Call_UpdateGroup_603278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group resource.
  ## 
  let valid = call_603289.validator(path, query, header, formData, body)
  let scheme = call_603289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603289.url(scheme.get, call_603289.host, call_603289.base,
                         call_603289.route, valid.getOrDefault("path"))
  result = hook(call_603289, url, valid)

proc call*(call_603290: Call_UpdateGroup_603278; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group resource.
  ##   body: JObject (required)
  var body_603291 = newJObject()
  if body != nil:
    body_603291 = body
  result = call_603290.call(nil, nil, nil, nil, body_603291)

var updateGroup* = Call_UpdateGroup_603278(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "xray.amazonaws.com",
                                        route: "/UpdateGroup",
                                        validator: validate_UpdateGroup_603279,
                                        base: "/", url: url_UpdateGroup_603280,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSamplingRule_603292 = ref object of OpenApiRestCall_602433
proc url_UpdateSamplingRule_603294(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateSamplingRule_603293(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Modifies a sampling rule's configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
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
  var valid_603295 = header.getOrDefault("X-Amz-Date")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Date", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Security-Token")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Security-Token", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Content-Sha256", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Algorithm")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Algorithm", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Signature")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Signature", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-SignedHeaders", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Credential")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Credential", valid_603301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603303: Call_UpdateSamplingRule_603292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a sampling rule's configuration.
  ## 
  let valid = call_603303.validator(path, query, header, formData, body)
  let scheme = call_603303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603303.url(scheme.get, call_603303.host, call_603303.base,
                         call_603303.route, valid.getOrDefault("path"))
  result = hook(call_603303, url, valid)

proc call*(call_603304: Call_UpdateSamplingRule_603292; body: JsonNode): Recallable =
  ## updateSamplingRule
  ## Modifies a sampling rule's configuration.
  ##   body: JObject (required)
  var body_603305 = newJObject()
  if body != nil:
    body_603305 = body
  result = call_603304.call(nil, nil, nil, nil, body_603305)

var updateSamplingRule* = Call_UpdateSamplingRule_603292(
    name: "updateSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/UpdateSamplingRule",
    validator: validate_UpdateSamplingRule_603293, base: "/",
    url: url_UpdateSamplingRule_603294, schemes: {Scheme.Https, Scheme.Http})
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

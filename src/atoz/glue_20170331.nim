
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Glue
## version: 2017-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Glue</fullname> <p>Defines the public endpoint for the AWS Glue service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/glue/
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "glue.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
                           "us-west-2": "glue.us-west-2.amazonaws.com",
                           "eu-west-2": "glue.eu-west-2.amazonaws.com", "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "glue.eu-central-1.amazonaws.com",
                           "us-east-2": "glue.us-east-2.amazonaws.com",
                           "us-east-1": "glue.us-east-1.amazonaws.com", "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "glue.ap-south-1.amazonaws.com",
                           "eu-north-1": "glue.eu-north-1.amazonaws.com", "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
                           "us-west-1": "glue.us-west-1.amazonaws.com",
                           "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "glue.eu-west-3.amazonaws.com",
                           "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "glue.sa-east-1.amazonaws.com",
                           "eu-west-1": "glue.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "glue.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
      "us-west-2": "glue.us-west-2.amazonaws.com",
      "eu-west-2": "glue.eu-west-2.amazonaws.com",
      "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
      "eu-central-1": "glue.eu-central-1.amazonaws.com",
      "us-east-2": "glue.us-east-2.amazonaws.com",
      "us-east-1": "glue.us-east-1.amazonaws.com",
      "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "glue.ap-south-1.amazonaws.com",
      "eu-north-1": "glue.eu-north-1.amazonaws.com",
      "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
      "us-west-1": "glue.us-west-1.amazonaws.com",
      "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
      "eu-west-3": "glue.eu-west-3.amazonaws.com",
      "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "glue.sa-east-1.amazonaws.com",
      "eu-west-1": "glue.eu-west-1.amazonaws.com",
      "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
      "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "glue"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_593774 = ref object of OpenApiRestCall_593437
proc url_BatchCreatePartition_593776(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchCreatePartition_593775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates one or more partitions in a batch operation.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_BatchCreatePartition_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_BatchCreatePartition_593774; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var batchCreatePartition* = Call_BatchCreatePartition_593774(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_593775, base: "/",
    url: url_BatchCreatePartition_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_594043 = ref object of OpenApiRestCall_593437
proc url_BatchDeleteConnection_594045(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteConnection_594044(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a list of connection definitions from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_BatchDeleteConnection_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_BatchDeleteConnection_594043; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var batchDeleteConnection* = Call_BatchDeleteConnection_594043(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_594044, base: "/",
    url: url_BatchDeleteConnection_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_594058 = ref object of OpenApiRestCall_593437
proc url_BatchDeletePartition_594060(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeletePartition_594059(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes one or more partitions in a batch operation.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_BatchDeletePartition_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_BatchDeletePartition_594058; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var batchDeletePartition* = Call_BatchDeletePartition_594058(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_594059, base: "/",
    url: url_BatchDeletePartition_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_594073 = ref object of OpenApiRestCall_593437
proc url_BatchDeleteTable_594075(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTable_594074(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_BatchDeleteTable_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_BatchDeleteTable_594073; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var batchDeleteTable* = Call_BatchDeleteTable_594073(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_594074, base: "/",
    url: url_BatchDeleteTable_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_594088 = ref object of OpenApiRestCall_593437
proc url_BatchDeleteTableVersion_594090(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTableVersion_594089(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified batch of versions of a table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_BatchDeleteTableVersion_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_BatchDeleteTableVersion_594088; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_594088(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_594089, base: "/",
    url: url_BatchDeleteTableVersion_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_594103 = ref object of OpenApiRestCall_593437
proc url_BatchGetCrawlers_594105(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetCrawlers_594104(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_BatchGetCrawlers_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_BatchGetCrawlers_594103; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var batchGetCrawlers* = Call_BatchGetCrawlers_594103(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_594104, base: "/",
    url: url_BatchGetCrawlers_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_594118 = ref object of OpenApiRestCall_593437
proc url_BatchGetDevEndpoints_594120(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDevEndpoints_594119(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_BatchGetDevEndpoints_594118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_BatchGetDevEndpoints_594118; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_594118(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_594119, base: "/",
    url: url_BatchGetDevEndpoints_594120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_594133 = ref object of OpenApiRestCall_593437
proc url_BatchGetJobs_594135(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetJobs_594134(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_BatchGetJobs_594133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_BatchGetJobs_594133; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var batchGetJobs* = Call_BatchGetJobs_594133(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_594134, base: "/", url: url_BatchGetJobs_594135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_594148 = ref object of OpenApiRestCall_593437
proc url_BatchGetPartition_594150(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetPartition_594149(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves partitions in a batch request.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_BatchGetPartition_594148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_BatchGetPartition_594148; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var batchGetPartition* = Call_BatchGetPartition_594148(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_594149, base: "/",
    url: url_BatchGetPartition_594150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_594163 = ref object of OpenApiRestCall_593437
proc url_BatchGetTriggers_594165(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetTriggers_594164(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_BatchGetTriggers_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_BatchGetTriggers_594163; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var batchGetTriggers* = Call_BatchGetTriggers_594163(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_594164, base: "/",
    url: url_BatchGetTriggers_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_594178 = ref object of OpenApiRestCall_593437
proc url_BatchGetWorkflows_594180(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetWorkflows_594179(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_BatchGetWorkflows_594178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_BatchGetWorkflows_594178; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var batchGetWorkflows* = Call_BatchGetWorkflows_594178(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_594179, base: "/",
    url: url_BatchGetWorkflows_594180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_594193 = ref object of OpenApiRestCall_593437
proc url_BatchStopJobRun_594195(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchStopJobRun_594194(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Stops one or more job runs for a specified job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_BatchStopJobRun_594193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_BatchStopJobRun_594193; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var batchStopJobRun* = Call_BatchStopJobRun_594193(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_594194, base: "/", url: url_BatchStopJobRun_594195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_594208 = ref object of OpenApiRestCall_593437
proc url_CancelMLTaskRun_594210(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelMLTaskRun_594209(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_CancelMLTaskRun_594208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_CancelMLTaskRun_594208; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var cancelMLTaskRun* = Call_CancelMLTaskRun_594208(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_594209, base: "/", url: url_CancelMLTaskRun_594210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_594223 = ref object of OpenApiRestCall_593437
proc url_CreateClassifier_594225(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateClassifier_594224(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_CreateClassifier_594223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_CreateClassifier_594223; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var createClassifier* = Call_CreateClassifier_594223(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_594224, base: "/",
    url: url_CreateClassifier_594225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_594238 = ref object of OpenApiRestCall_593437
proc url_CreateConnection_594240(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConnection_594239(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a connection definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594243 = header.getOrDefault("X-Amz-Target")
  valid_594243 = validateParameter(valid_594243, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_594243 != nil:
    section.add "X-Amz-Target", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-SignedHeaders", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Credential")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Credential", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_CreateConnection_594238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_CreateConnection_594238; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_594252 = newJObject()
  if body != nil:
    body_594252 = body
  result = call_594251.call(nil, nil, nil, nil, body_594252)

var createConnection* = Call_CreateConnection_594238(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_594239, base: "/",
    url: url_CreateConnection_594240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_594253 = ref object of OpenApiRestCall_593437
proc url_CreateCrawler_594255(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCrawler_594254(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594258 = header.getOrDefault("X-Amz-Target")
  valid_594258 = validateParameter(valid_594258, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_594258 != nil:
    section.add "X-Amz-Target", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_CreateCrawler_594253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_CreateCrawler_594253; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var createCrawler* = Call_CreateCrawler_594253(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_594254, base: "/", url: url_CreateCrawler_594255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_594268 = ref object of OpenApiRestCall_593437
proc url_CreateDatabase_594270(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatabase_594269(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new database in a Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594273 = header.getOrDefault("X-Amz-Target")
  valid_594273 = validateParameter(valid_594273, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_594273 != nil:
    section.add "X-Amz-Target", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_CreateDatabase_594268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_CreateDatabase_594268; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_594282 = newJObject()
  if body != nil:
    body_594282 = body
  result = call_594281.call(nil, nil, nil, nil, body_594282)

var createDatabase* = Call_CreateDatabase_594268(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_594269, base: "/", url: url_CreateDatabase_594270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_594283 = ref object of OpenApiRestCall_593437
proc url_CreateDevEndpoint_594285(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDevEndpoint_594284(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a new development endpoint.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594288 = header.getOrDefault("X-Amz-Target")
  valid_594288 = validateParameter(valid_594288, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_594288 != nil:
    section.add "X-Amz-Target", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_CreateDevEndpoint_594283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_CreateDevEndpoint_594283; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_594297 = newJObject()
  if body != nil:
    body_594297 = body
  result = call_594296.call(nil, nil, nil, nil, body_594297)

var createDevEndpoint* = Call_CreateDevEndpoint_594283(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_594284, base: "/",
    url: url_CreateDevEndpoint_594285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_594298 = ref object of OpenApiRestCall_593437
proc url_CreateJob_594300(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_594299(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Security-Token")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Security-Token", valid_594302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594303 = header.getOrDefault("X-Amz-Target")
  valid_594303 = validateParameter(valid_594303, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_594303 != nil:
    section.add "X-Amz-Target", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_CreateJob_594298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_CreateJob_594298; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_594312 = newJObject()
  if body != nil:
    body_594312 = body
  result = call_594311.call(nil, nil, nil, nil, body_594312)

var createJob* = Call_CreateJob_594298(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_594299,
                                    base: "/", url: url_CreateJob_594300,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_594313 = ref object of OpenApiRestCall_593437
proc url_CreateMLTransform_594315(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMLTransform_594314(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Security-Token")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Security-Token", valid_594317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594318 = header.getOrDefault("X-Amz-Target")
  valid_594318 = validateParameter(valid_594318, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_594318 != nil:
    section.add "X-Amz-Target", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Content-Sha256", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Signature")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Signature", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Credential")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Credential", valid_594323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_CreateMLTransform_594313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_CreateMLTransform_594313; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_594327 = newJObject()
  if body != nil:
    body_594327 = body
  result = call_594326.call(nil, nil, nil, nil, body_594327)

var createMLTransform* = Call_CreateMLTransform_594313(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_594314, base: "/",
    url: url_CreateMLTransform_594315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_594328 = ref object of OpenApiRestCall_593437
proc url_CreatePartition_594330(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePartition_594329(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594333 = header.getOrDefault("X-Amz-Target")
  valid_594333 = validateParameter(valid_594333, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_594333 != nil:
    section.add "X-Amz-Target", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Content-Sha256", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Algorithm")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Algorithm", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Signature")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Signature", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Credential")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Credential", valid_594338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_CreatePartition_594328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_CreatePartition_594328; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_594342 = newJObject()
  if body != nil:
    body_594342 = body
  result = call_594341.call(nil, nil, nil, nil, body_594342)

var createPartition* = Call_CreatePartition_594328(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_594329, base: "/", url: url_CreatePartition_594330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_594343 = ref object of OpenApiRestCall_593437
proc url_CreateScript_594345(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateScript_594344(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Transforms a directed acyclic graph (DAG) into code.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594348 = header.getOrDefault("X-Amz-Target")
  valid_594348 = validateParameter(valid_594348, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_594348 != nil:
    section.add "X-Amz-Target", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_CreateScript_594343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_CreateScript_594343; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_594357 = newJObject()
  if body != nil:
    body_594357 = body
  result = call_594356.call(nil, nil, nil, nil, body_594357)

var createScript* = Call_CreateScript_594343(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_594344, base: "/", url: url_CreateScript_594345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_594358 = ref object of OpenApiRestCall_593437
proc url_CreateSecurityConfiguration_594360(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSecurityConfiguration_594359(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Security-Token")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Security-Token", valid_594362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594363 = header.getOrDefault("X-Amz-Target")
  valid_594363 = validateParameter(valid_594363, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_594363 != nil:
    section.add "X-Amz-Target", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Signature")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Signature", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Credential")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Credential", valid_594368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_CreateSecurityConfiguration_594358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_CreateSecurityConfiguration_594358; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_594372 = newJObject()
  if body != nil:
    body_594372 = body
  result = call_594371.call(nil, nil, nil, nil, body_594372)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_594358(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_594359, base: "/",
    url: url_CreateSecurityConfiguration_594360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_594373 = ref object of OpenApiRestCall_593437
proc url_CreateTable_594375(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTable_594374(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new table definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594376 = header.getOrDefault("X-Amz-Date")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Date", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Security-Token")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Security-Token", valid_594377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594378 = header.getOrDefault("X-Amz-Target")
  valid_594378 = validateParameter(valid_594378, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_594378 != nil:
    section.add "X-Amz-Target", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594385: Call_CreateTable_594373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_594385.validator(path, query, header, formData, body)
  let scheme = call_594385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594385.url(scheme.get, call_594385.host, call_594385.base,
                         call_594385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594385, url, valid)

proc call*(call_594386: Call_CreateTable_594373; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_594387 = newJObject()
  if body != nil:
    body_594387 = body
  result = call_594386.call(nil, nil, nil, nil, body_594387)

var createTable* = Call_CreateTable_594373(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_594374,
                                        base: "/", url: url_CreateTable_594375,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_594388 = ref object of OpenApiRestCall_593437
proc url_CreateTrigger_594390(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrigger_594389(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new trigger.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594391 = header.getOrDefault("X-Amz-Date")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Date", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Security-Token")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Security-Token", valid_594392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594393 = header.getOrDefault("X-Amz-Target")
  valid_594393 = validateParameter(valid_594393, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_594393 != nil:
    section.add "X-Amz-Target", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Content-Sha256", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Algorithm")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Algorithm", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Signature")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Signature", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-SignedHeaders", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Credential")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Credential", valid_594398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594400: Call_CreateTrigger_594388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_594400.validator(path, query, header, formData, body)
  let scheme = call_594400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594400.url(scheme.get, call_594400.host, call_594400.base,
                         call_594400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594400, url, valid)

proc call*(call_594401: Call_CreateTrigger_594388; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_594402 = newJObject()
  if body != nil:
    body_594402 = body
  result = call_594401.call(nil, nil, nil, nil, body_594402)

var createTrigger* = Call_CreateTrigger_594388(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_594389, base: "/", url: url_CreateTrigger_594390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_594403 = ref object of OpenApiRestCall_593437
proc url_CreateUserDefinedFunction_594405(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUserDefinedFunction_594404(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new function definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594406 = header.getOrDefault("X-Amz-Date")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Date", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Security-Token")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Security-Token", valid_594407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594408 = header.getOrDefault("X-Amz-Target")
  valid_594408 = validateParameter(valid_594408, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_594408 != nil:
    section.add "X-Amz-Target", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Content-Sha256", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Algorithm")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Algorithm", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Signature")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Signature", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-SignedHeaders", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Credential")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Credential", valid_594413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594415: Call_CreateUserDefinedFunction_594403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_594415.validator(path, query, header, formData, body)
  let scheme = call_594415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594415.url(scheme.get, call_594415.host, call_594415.base,
                         call_594415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594415, url, valid)

proc call*(call_594416: Call_CreateUserDefinedFunction_594403; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_594417 = newJObject()
  if body != nil:
    body_594417 = body
  result = call_594416.call(nil, nil, nil, nil, body_594417)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_594403(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_594404, base: "/",
    url: url_CreateUserDefinedFunction_594405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_594418 = ref object of OpenApiRestCall_593437
proc url_CreateWorkflow_594420(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkflow_594419(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594421 = header.getOrDefault("X-Amz-Date")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Date", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Security-Token")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Security-Token", valid_594422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594423 = header.getOrDefault("X-Amz-Target")
  valid_594423 = validateParameter(valid_594423, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_594423 != nil:
    section.add "X-Amz-Target", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Content-Sha256", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Algorithm")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Algorithm", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-SignedHeaders", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Credential")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Credential", valid_594428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594430: Call_CreateWorkflow_594418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_594430.validator(path, query, header, formData, body)
  let scheme = call_594430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594430.url(scheme.get, call_594430.host, call_594430.base,
                         call_594430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594430, url, valid)

proc call*(call_594431: Call_CreateWorkflow_594418; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_594432 = newJObject()
  if body != nil:
    body_594432 = body
  result = call_594431.call(nil, nil, nil, nil, body_594432)

var createWorkflow* = Call_CreateWorkflow_594418(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_594419, base: "/", url: url_CreateWorkflow_594420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_594433 = ref object of OpenApiRestCall_593437
proc url_DeleteClassifier_594435(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteClassifier_594434(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes a classifier from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594436 = header.getOrDefault("X-Amz-Date")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Date", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Security-Token")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Security-Token", valid_594437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594438 = header.getOrDefault("X-Amz-Target")
  valid_594438 = validateParameter(valid_594438, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_594438 != nil:
    section.add "X-Amz-Target", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Content-Sha256", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Algorithm")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Algorithm", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Signature")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Signature", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-SignedHeaders", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Credential")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Credential", valid_594443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594445: Call_DeleteClassifier_594433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_594445.validator(path, query, header, formData, body)
  let scheme = call_594445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594445.url(scheme.get, call_594445.host, call_594445.base,
                         call_594445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594445, url, valid)

proc call*(call_594446: Call_DeleteClassifier_594433; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_594447 = newJObject()
  if body != nil:
    body_594447 = body
  result = call_594446.call(nil, nil, nil, nil, body_594447)

var deleteClassifier* = Call_DeleteClassifier_594433(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_594434, base: "/",
    url: url_DeleteClassifier_594435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_594448 = ref object of OpenApiRestCall_593437
proc url_DeleteConnection_594450(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConnection_594449(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a connection from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594451 = header.getOrDefault("X-Amz-Date")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Date", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Security-Token")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Security-Token", valid_594452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594453 = header.getOrDefault("X-Amz-Target")
  valid_594453 = validateParameter(valid_594453, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_594453 != nil:
    section.add "X-Amz-Target", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Content-Sha256", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Algorithm")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Algorithm", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Signature")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Signature", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-SignedHeaders", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Credential")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Credential", valid_594458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594460: Call_DeleteConnection_594448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_594460.validator(path, query, header, formData, body)
  let scheme = call_594460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594460.url(scheme.get, call_594460.host, call_594460.base,
                         call_594460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594460, url, valid)

proc call*(call_594461: Call_DeleteConnection_594448; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_594462 = newJObject()
  if body != nil:
    body_594462 = body
  result = call_594461.call(nil, nil, nil, nil, body_594462)

var deleteConnection* = Call_DeleteConnection_594448(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_594449, base: "/",
    url: url_DeleteConnection_594450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_594463 = ref object of OpenApiRestCall_593437
proc url_DeleteCrawler_594465(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCrawler_594464(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594466 = header.getOrDefault("X-Amz-Date")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Date", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Security-Token")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Security-Token", valid_594467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594468 = header.getOrDefault("X-Amz-Target")
  valid_594468 = validateParameter(valid_594468, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_594468 != nil:
    section.add "X-Amz-Target", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Content-Sha256", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Algorithm")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Algorithm", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Signature")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Signature", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-SignedHeaders", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Credential")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Credential", valid_594473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_DeleteCrawler_594463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_DeleteCrawler_594463; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_594477 = newJObject()
  if body != nil:
    body_594477 = body
  result = call_594476.call(nil, nil, nil, nil, body_594477)

var deleteCrawler* = Call_DeleteCrawler_594463(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_594464, base: "/", url: url_DeleteCrawler_594465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_594478 = ref object of OpenApiRestCall_593437
proc url_DeleteDatabase_594480(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDatabase_594479(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594481 = header.getOrDefault("X-Amz-Date")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Date", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Security-Token")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Security-Token", valid_594482
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594483 = header.getOrDefault("X-Amz-Target")
  valid_594483 = validateParameter(valid_594483, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_594483 != nil:
    section.add "X-Amz-Target", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Content-Sha256", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Algorithm")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Algorithm", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Signature")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Signature", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-SignedHeaders", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Credential")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Credential", valid_594488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594490: Call_DeleteDatabase_594478; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_594490.validator(path, query, header, formData, body)
  let scheme = call_594490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594490.url(scheme.get, call_594490.host, call_594490.base,
                         call_594490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594490, url, valid)

proc call*(call_594491: Call_DeleteDatabase_594478; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_594492 = newJObject()
  if body != nil:
    body_594492 = body
  result = call_594491.call(nil, nil, nil, nil, body_594492)

var deleteDatabase* = Call_DeleteDatabase_594478(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_594479, base: "/", url: url_DeleteDatabase_594480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_594493 = ref object of OpenApiRestCall_593437
proc url_DeleteDevEndpoint_594495(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevEndpoint_594494(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes a specified development endpoint.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594496 = header.getOrDefault("X-Amz-Date")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Date", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Security-Token")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Security-Token", valid_594497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594498 = header.getOrDefault("X-Amz-Target")
  valid_594498 = validateParameter(valid_594498, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_594498 != nil:
    section.add "X-Amz-Target", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Content-Sha256", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Algorithm")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Algorithm", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Signature")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Signature", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-SignedHeaders", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Credential")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Credential", valid_594503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594505: Call_DeleteDevEndpoint_594493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_594505.validator(path, query, header, formData, body)
  let scheme = call_594505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594505.url(scheme.get, call_594505.host, call_594505.base,
                         call_594505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594505, url, valid)

proc call*(call_594506: Call_DeleteDevEndpoint_594493; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_594507 = newJObject()
  if body != nil:
    body_594507 = body
  result = call_594506.call(nil, nil, nil, nil, body_594507)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_594493(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_594494, base: "/",
    url: url_DeleteDevEndpoint_594495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_594508 = ref object of OpenApiRestCall_593437
proc url_DeleteJob_594510(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteJob_594509(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594511 = header.getOrDefault("X-Amz-Date")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Date", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Security-Token")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Security-Token", valid_594512
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594513 = header.getOrDefault("X-Amz-Target")
  valid_594513 = validateParameter(valid_594513, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_594513 != nil:
    section.add "X-Amz-Target", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Content-Sha256", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Algorithm")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Algorithm", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Signature")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Signature", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-SignedHeaders", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Credential")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Credential", valid_594518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594520: Call_DeleteJob_594508; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_594520.validator(path, query, header, formData, body)
  let scheme = call_594520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594520.url(scheme.get, call_594520.host, call_594520.base,
                         call_594520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594520, url, valid)

proc call*(call_594521: Call_DeleteJob_594508; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_594522 = newJObject()
  if body != nil:
    body_594522 = body
  result = call_594521.call(nil, nil, nil, nil, body_594522)

var deleteJob* = Call_DeleteJob_594508(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_594509,
                                    base: "/", url: url_DeleteJob_594510,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_594523 = ref object of OpenApiRestCall_593437
proc url_DeleteMLTransform_594525(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMLTransform_594524(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594526 = header.getOrDefault("X-Amz-Date")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Date", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Security-Token")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Security-Token", valid_594527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594528 = header.getOrDefault("X-Amz-Target")
  valid_594528 = validateParameter(valid_594528, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_594528 != nil:
    section.add "X-Amz-Target", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Content-Sha256", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Algorithm")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Algorithm", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-SignedHeaders", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Credential")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Credential", valid_594533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594535: Call_DeleteMLTransform_594523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_594535.validator(path, query, header, formData, body)
  let scheme = call_594535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594535.url(scheme.get, call_594535.host, call_594535.base,
                         call_594535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594535, url, valid)

proc call*(call_594536: Call_DeleteMLTransform_594523; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_594537 = newJObject()
  if body != nil:
    body_594537 = body
  result = call_594536.call(nil, nil, nil, nil, body_594537)

var deleteMLTransform* = Call_DeleteMLTransform_594523(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_594524, base: "/",
    url: url_DeleteMLTransform_594525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_594538 = ref object of OpenApiRestCall_593437
proc url_DeletePartition_594540(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePartition_594539(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a specified partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594541 = header.getOrDefault("X-Amz-Date")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Date", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Security-Token")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Security-Token", valid_594542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594543 = header.getOrDefault("X-Amz-Target")
  valid_594543 = validateParameter(valid_594543, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_594543 != nil:
    section.add "X-Amz-Target", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Content-Sha256", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-Algorithm")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Algorithm", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Signature")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Signature", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-SignedHeaders", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Credential")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Credential", valid_594548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594550: Call_DeletePartition_594538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_594550.validator(path, query, header, formData, body)
  let scheme = call_594550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594550.url(scheme.get, call_594550.host, call_594550.base,
                         call_594550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594550, url, valid)

proc call*(call_594551: Call_DeletePartition_594538; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_594552 = newJObject()
  if body != nil:
    body_594552 = body
  result = call_594551.call(nil, nil, nil, nil, body_594552)

var deletePartition* = Call_DeletePartition_594538(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_594539, base: "/", url: url_DeletePartition_594540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_594553 = ref object of OpenApiRestCall_593437
proc url_DeleteResourcePolicy_594555(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourcePolicy_594554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified policy.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Security-Token")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Security-Token", valid_594557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594558 = header.getOrDefault("X-Amz-Target")
  valid_594558 = validateParameter(valid_594558, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_594558 != nil:
    section.add "X-Amz-Target", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Content-Sha256", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Algorithm")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Algorithm", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Signature")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Signature", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-SignedHeaders", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Credential")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Credential", valid_594563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594565: Call_DeleteResourcePolicy_594553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_594565.validator(path, query, header, formData, body)
  let scheme = call_594565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594565.url(scheme.get, call_594565.host, call_594565.base,
                         call_594565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594565, url, valid)

proc call*(call_594566: Call_DeleteResourcePolicy_594553; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_594567 = newJObject()
  if body != nil:
    body_594567 = body
  result = call_594566.call(nil, nil, nil, nil, body_594567)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_594553(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_594554, base: "/",
    url: url_DeleteResourcePolicy_594555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_594568 = ref object of OpenApiRestCall_593437
proc url_DeleteSecurityConfiguration_594570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSecurityConfiguration_594569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified security configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Security-Token")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Security-Token", valid_594572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594573 = header.getOrDefault("X-Amz-Target")
  valid_594573 = validateParameter(valid_594573, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_594573 != nil:
    section.add "X-Amz-Target", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Content-Sha256", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Algorithm")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Algorithm", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Signature")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Signature", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-SignedHeaders", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Credential")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Credential", valid_594578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594580: Call_DeleteSecurityConfiguration_594568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_594580.validator(path, query, header, formData, body)
  let scheme = call_594580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594580.url(scheme.get, call_594580.host, call_594580.base,
                         call_594580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594580, url, valid)

proc call*(call_594581: Call_DeleteSecurityConfiguration_594568; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_594582 = newJObject()
  if body != nil:
    body_594582 = body
  result = call_594581.call(nil, nil, nil, nil, body_594582)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_594568(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_594569, base: "/",
    url: url_DeleteSecurityConfiguration_594570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_594583 = ref object of OpenApiRestCall_593437
proc url_DeleteTable_594585(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTable_594584(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594586 = header.getOrDefault("X-Amz-Date")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Date", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Security-Token")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Security-Token", valid_594587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594588 = header.getOrDefault("X-Amz-Target")
  valid_594588 = validateParameter(valid_594588, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_594588 != nil:
    section.add "X-Amz-Target", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Content-Sha256", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Algorithm")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Algorithm", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Signature")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Signature", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-SignedHeaders", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Credential")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Credential", valid_594593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594595: Call_DeleteTable_594583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_594595.validator(path, query, header, formData, body)
  let scheme = call_594595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594595.url(scheme.get, call_594595.host, call_594595.base,
                         call_594595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594595, url, valid)

proc call*(call_594596: Call_DeleteTable_594583; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_594597 = newJObject()
  if body != nil:
    body_594597 = body
  result = call_594596.call(nil, nil, nil, nil, body_594597)

var deleteTable* = Call_DeleteTable_594583(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_594584,
                                        base: "/", url: url_DeleteTable_594585,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_594598 = ref object of OpenApiRestCall_593437
proc url_DeleteTableVersion_594600(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTableVersion_594599(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a specified version of a table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594601 = header.getOrDefault("X-Amz-Date")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Date", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Security-Token")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Security-Token", valid_594602
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594603 = header.getOrDefault("X-Amz-Target")
  valid_594603 = validateParameter(valid_594603, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_594603 != nil:
    section.add "X-Amz-Target", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Content-Sha256", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Algorithm")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Algorithm", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-SignedHeaders", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Credential")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Credential", valid_594608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594610: Call_DeleteTableVersion_594598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_594610.validator(path, query, header, formData, body)
  let scheme = call_594610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594610.url(scheme.get, call_594610.host, call_594610.base,
                         call_594610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594610, url, valid)

proc call*(call_594611: Call_DeleteTableVersion_594598; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_594612 = newJObject()
  if body != nil:
    body_594612 = body
  result = call_594611.call(nil, nil, nil, nil, body_594612)

var deleteTableVersion* = Call_DeleteTableVersion_594598(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_594599, base: "/",
    url: url_DeleteTableVersion_594600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_594613 = ref object of OpenApiRestCall_593437
proc url_DeleteTrigger_594615(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTrigger_594614(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594616 = header.getOrDefault("X-Amz-Date")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Date", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Security-Token")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Security-Token", valid_594617
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594618 = header.getOrDefault("X-Amz-Target")
  valid_594618 = validateParameter(valid_594618, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_594618 != nil:
    section.add "X-Amz-Target", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Content-Sha256", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Algorithm")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Algorithm", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Signature")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Signature", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-SignedHeaders", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Credential")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Credential", valid_594623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594625: Call_DeleteTrigger_594613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_594625.validator(path, query, header, formData, body)
  let scheme = call_594625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594625.url(scheme.get, call_594625.host, call_594625.base,
                         call_594625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594625, url, valid)

proc call*(call_594626: Call_DeleteTrigger_594613; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_594627 = newJObject()
  if body != nil:
    body_594627 = body
  result = call_594626.call(nil, nil, nil, nil, body_594627)

var deleteTrigger* = Call_DeleteTrigger_594613(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_594614, base: "/", url: url_DeleteTrigger_594615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_594628 = ref object of OpenApiRestCall_593437
proc url_DeleteUserDefinedFunction_594630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUserDefinedFunction_594629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing function definition from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594631 = header.getOrDefault("X-Amz-Date")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Date", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Security-Token")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Security-Token", valid_594632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594633 = header.getOrDefault("X-Amz-Target")
  valid_594633 = validateParameter(valid_594633, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_594633 != nil:
    section.add "X-Amz-Target", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Content-Sha256", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Algorithm")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Algorithm", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Signature")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Signature", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-SignedHeaders", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Credential")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Credential", valid_594638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594640: Call_DeleteUserDefinedFunction_594628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_594640.validator(path, query, header, formData, body)
  let scheme = call_594640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594640.url(scheme.get, call_594640.host, call_594640.base,
                         call_594640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594640, url, valid)

proc call*(call_594641: Call_DeleteUserDefinedFunction_594628; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_594642 = newJObject()
  if body != nil:
    body_594642 = body
  result = call_594641.call(nil, nil, nil, nil, body_594642)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_594628(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_594629, base: "/",
    url: url_DeleteUserDefinedFunction_594630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_594643 = ref object of OpenApiRestCall_593437
proc url_DeleteWorkflow_594645(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkflow_594644(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594646 = header.getOrDefault("X-Amz-Date")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Date", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Security-Token")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Security-Token", valid_594647
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594648 = header.getOrDefault("X-Amz-Target")
  valid_594648 = validateParameter(valid_594648, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_594648 != nil:
    section.add "X-Amz-Target", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Content-Sha256", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Algorithm")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Algorithm", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Signature")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Signature", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-SignedHeaders", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Credential")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Credential", valid_594653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594655: Call_DeleteWorkflow_594643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_594655.validator(path, query, header, formData, body)
  let scheme = call_594655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594655.url(scheme.get, call_594655.host, call_594655.base,
                         call_594655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594655, url, valid)

proc call*(call_594656: Call_DeleteWorkflow_594643; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_594657 = newJObject()
  if body != nil:
    body_594657 = body
  result = call_594656.call(nil, nil, nil, nil, body_594657)

var deleteWorkflow* = Call_DeleteWorkflow_594643(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_594644, base: "/", url: url_DeleteWorkflow_594645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_594658 = ref object of OpenApiRestCall_593437
proc url_GetCatalogImportStatus_594660(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCatalogImportStatus_594659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the status of a migration operation.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594661 = header.getOrDefault("X-Amz-Date")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Date", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Security-Token")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Security-Token", valid_594662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594663 = header.getOrDefault("X-Amz-Target")
  valid_594663 = validateParameter(valid_594663, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_594663 != nil:
    section.add "X-Amz-Target", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Content-Sha256", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Algorithm")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Algorithm", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Signature")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Signature", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-SignedHeaders", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Credential")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Credential", valid_594668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594670: Call_GetCatalogImportStatus_594658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_594670.validator(path, query, header, formData, body)
  let scheme = call_594670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594670.url(scheme.get, call_594670.host, call_594670.base,
                         call_594670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594670, url, valid)

proc call*(call_594671: Call_GetCatalogImportStatus_594658; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_594672 = newJObject()
  if body != nil:
    body_594672 = body
  result = call_594671.call(nil, nil, nil, nil, body_594672)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_594658(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_594659, base: "/",
    url: url_GetCatalogImportStatus_594660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_594673 = ref object of OpenApiRestCall_593437
proc url_GetClassifier_594675(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifier_594674(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a classifier by name.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594676 = header.getOrDefault("X-Amz-Date")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Date", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Security-Token")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Security-Token", valid_594677
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594678 = header.getOrDefault("X-Amz-Target")
  valid_594678 = validateParameter(valid_594678, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_594678 != nil:
    section.add "X-Amz-Target", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Content-Sha256", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Algorithm")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Algorithm", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Signature")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Signature", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-SignedHeaders", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Credential")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Credential", valid_594683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594685: Call_GetClassifier_594673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_594685.validator(path, query, header, formData, body)
  let scheme = call_594685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594685.url(scheme.get, call_594685.host, call_594685.base,
                         call_594685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594685, url, valid)

proc call*(call_594686: Call_GetClassifier_594673; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_594687 = newJObject()
  if body != nil:
    body_594687 = body
  result = call_594686.call(nil, nil, nil, nil, body_594687)

var getClassifier* = Call_GetClassifier_594673(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_594674, base: "/", url: url_GetClassifier_594675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_594688 = ref object of OpenApiRestCall_593437
proc url_GetClassifiers_594690(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifiers_594689(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594691 = query.getOrDefault("NextToken")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "NextToken", valid_594691
  var valid_594692 = query.getOrDefault("MaxResults")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "MaxResults", valid_594692
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594693 = header.getOrDefault("X-Amz-Date")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-Date", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Security-Token")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Security-Token", valid_594694
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594695 = header.getOrDefault("X-Amz-Target")
  valid_594695 = validateParameter(valid_594695, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_594695 != nil:
    section.add "X-Amz-Target", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Content-Sha256", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Algorithm")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Algorithm", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Signature")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Signature", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-SignedHeaders", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Credential")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Credential", valid_594700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594702: Call_GetClassifiers_594688; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_594702.validator(path, query, header, formData, body)
  let scheme = call_594702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594702.url(scheme.get, call_594702.host, call_594702.base,
                         call_594702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594702, url, valid)

proc call*(call_594703: Call_GetClassifiers_594688; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594704 = newJObject()
  var body_594705 = newJObject()
  add(query_594704, "NextToken", newJString(NextToken))
  if body != nil:
    body_594705 = body
  add(query_594704, "MaxResults", newJString(MaxResults))
  result = call_594703.call(nil, query_594704, nil, nil, body_594705)

var getClassifiers* = Call_GetClassifiers_594688(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_594689, base: "/", url: url_GetClassifiers_594690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_594707 = ref object of OpenApiRestCall_593437
proc url_GetConnection_594709(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnection_594708(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a connection definition from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594710 = header.getOrDefault("X-Amz-Date")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Date", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Security-Token")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Security-Token", valid_594711
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594712 = header.getOrDefault("X-Amz-Target")
  valid_594712 = validateParameter(valid_594712, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_594712 != nil:
    section.add "X-Amz-Target", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Content-Sha256", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Algorithm")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Algorithm", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-Signature")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-Signature", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-SignedHeaders", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-Credential")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Credential", valid_594717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594719: Call_GetConnection_594707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_594719.validator(path, query, header, formData, body)
  let scheme = call_594719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594719.url(scheme.get, call_594719.host, call_594719.base,
                         call_594719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594719, url, valid)

proc call*(call_594720: Call_GetConnection_594707; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_594721 = newJObject()
  if body != nil:
    body_594721 = body
  result = call_594720.call(nil, nil, nil, nil, body_594721)

var getConnection* = Call_GetConnection_594707(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_594708, base: "/", url: url_GetConnection_594709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_594722 = ref object of OpenApiRestCall_593437
proc url_GetConnections_594724(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnections_594723(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594725 = query.getOrDefault("NextToken")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "NextToken", valid_594725
  var valid_594726 = query.getOrDefault("MaxResults")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "MaxResults", valid_594726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594727 = header.getOrDefault("X-Amz-Date")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-Date", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Security-Token")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Security-Token", valid_594728
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594729 = header.getOrDefault("X-Amz-Target")
  valid_594729 = validateParameter(valid_594729, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_594729 != nil:
    section.add "X-Amz-Target", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Content-Sha256", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Algorithm")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Algorithm", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Signature")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Signature", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-SignedHeaders", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-Credential")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-Credential", valid_594734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594736: Call_GetConnections_594722; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_594736.validator(path, query, header, formData, body)
  let scheme = call_594736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594736.url(scheme.get, call_594736.host, call_594736.base,
                         call_594736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594736, url, valid)

proc call*(call_594737: Call_GetConnections_594722; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594738 = newJObject()
  var body_594739 = newJObject()
  add(query_594738, "NextToken", newJString(NextToken))
  if body != nil:
    body_594739 = body
  add(query_594738, "MaxResults", newJString(MaxResults))
  result = call_594737.call(nil, query_594738, nil, nil, body_594739)

var getConnections* = Call_GetConnections_594722(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_594723, base: "/", url: url_GetConnections_594724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_594740 = ref object of OpenApiRestCall_593437
proc url_GetCrawler_594742(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawler_594741(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for a specified crawler.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594743 = header.getOrDefault("X-Amz-Date")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Date", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Security-Token")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Security-Token", valid_594744
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594745 = header.getOrDefault("X-Amz-Target")
  valid_594745 = validateParameter(valid_594745, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_594745 != nil:
    section.add "X-Amz-Target", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Content-Sha256", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Algorithm")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Algorithm", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Signature")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Signature", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-SignedHeaders", valid_594749
  var valid_594750 = header.getOrDefault("X-Amz-Credential")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "X-Amz-Credential", valid_594750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594752: Call_GetCrawler_594740; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_594752.validator(path, query, header, formData, body)
  let scheme = call_594752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594752.url(scheme.get, call_594752.host, call_594752.base,
                         call_594752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594752, url, valid)

proc call*(call_594753: Call_GetCrawler_594740; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_594754 = newJObject()
  if body != nil:
    body_594754 = body
  result = call_594753.call(nil, nil, nil, nil, body_594754)

var getCrawler* = Call_GetCrawler_594740(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_594741,
                                      base: "/", url: url_GetCrawler_594742,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_594755 = ref object of OpenApiRestCall_593437
proc url_GetCrawlerMetrics_594757(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlerMetrics_594756(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves metrics about specified crawlers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594758 = query.getOrDefault("NextToken")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "NextToken", valid_594758
  var valid_594759 = query.getOrDefault("MaxResults")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "MaxResults", valid_594759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594760 = header.getOrDefault("X-Amz-Date")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Date", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-Security-Token")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Security-Token", valid_594761
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594762 = header.getOrDefault("X-Amz-Target")
  valid_594762 = validateParameter(valid_594762, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_594762 != nil:
    section.add "X-Amz-Target", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Content-Sha256", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Algorithm")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Algorithm", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Signature")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Signature", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-SignedHeaders", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Credential")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Credential", valid_594767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594769: Call_GetCrawlerMetrics_594755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_594769.validator(path, query, header, formData, body)
  let scheme = call_594769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594769.url(scheme.get, call_594769.host, call_594769.base,
                         call_594769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594769, url, valid)

proc call*(call_594770: Call_GetCrawlerMetrics_594755; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594771 = newJObject()
  var body_594772 = newJObject()
  add(query_594771, "NextToken", newJString(NextToken))
  if body != nil:
    body_594772 = body
  add(query_594771, "MaxResults", newJString(MaxResults))
  result = call_594770.call(nil, query_594771, nil, nil, body_594772)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_594755(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_594756, base: "/",
    url: url_GetCrawlerMetrics_594757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_594773 = ref object of OpenApiRestCall_593437
proc url_GetCrawlers_594775(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlers_594774(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594776 = query.getOrDefault("NextToken")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "NextToken", valid_594776
  var valid_594777 = query.getOrDefault("MaxResults")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "MaxResults", valid_594777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594778 = header.getOrDefault("X-Amz-Date")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Date", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Security-Token")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Security-Token", valid_594779
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594780 = header.getOrDefault("X-Amz-Target")
  valid_594780 = validateParameter(valid_594780, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_594780 != nil:
    section.add "X-Amz-Target", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Content-Sha256", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Algorithm")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Algorithm", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-Signature")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Signature", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-SignedHeaders", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-Credential")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-Credential", valid_594785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594787: Call_GetCrawlers_594773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_594787.validator(path, query, header, formData, body)
  let scheme = call_594787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594787.url(scheme.get, call_594787.host, call_594787.base,
                         call_594787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594787, url, valid)

proc call*(call_594788: Call_GetCrawlers_594773; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594789 = newJObject()
  var body_594790 = newJObject()
  add(query_594789, "NextToken", newJString(NextToken))
  if body != nil:
    body_594790 = body
  add(query_594789, "MaxResults", newJString(MaxResults))
  result = call_594788.call(nil, query_594789, nil, nil, body_594790)

var getCrawlers* = Call_GetCrawlers_594773(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_594774,
                                        base: "/", url: url_GetCrawlers_594775,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_594791 = ref object of OpenApiRestCall_593437
proc url_GetDataCatalogEncryptionSettings_594793(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_594792(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the security configuration for a specified catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594794 = header.getOrDefault("X-Amz-Date")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Date", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Security-Token")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Security-Token", valid_594795
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594796 = header.getOrDefault("X-Amz-Target")
  valid_594796 = validateParameter(valid_594796, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_594796 != nil:
    section.add "X-Amz-Target", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Content-Sha256", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-Algorithm")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Algorithm", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Signature")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Signature", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-SignedHeaders", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-Credential")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Credential", valid_594801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594803: Call_GetDataCatalogEncryptionSettings_594791;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_594803.validator(path, query, header, formData, body)
  let scheme = call_594803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594803.url(scheme.get, call_594803.host, call_594803.base,
                         call_594803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594803, url, valid)

proc call*(call_594804: Call_GetDataCatalogEncryptionSettings_594791;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_594805 = newJObject()
  if body != nil:
    body_594805 = body
  result = call_594804.call(nil, nil, nil, nil, body_594805)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_594791(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_594792, base: "/",
    url: url_GetDataCatalogEncryptionSettings_594793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_594806 = ref object of OpenApiRestCall_593437
proc url_GetDatabase_594808(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabase_594807(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a specified database.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594809 = header.getOrDefault("X-Amz-Date")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Date", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Security-Token")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Security-Token", valid_594810
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594811 = header.getOrDefault("X-Amz-Target")
  valid_594811 = validateParameter(valid_594811, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_594811 != nil:
    section.add "X-Amz-Target", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Content-Sha256", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-Algorithm")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Algorithm", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Signature")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Signature", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-SignedHeaders", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Credential")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Credential", valid_594816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594818: Call_GetDatabase_594806; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_594818.validator(path, query, header, formData, body)
  let scheme = call_594818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594818.url(scheme.get, call_594818.host, call_594818.base,
                         call_594818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594818, url, valid)

proc call*(call_594819: Call_GetDatabase_594806; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_594820 = newJObject()
  if body != nil:
    body_594820 = body
  result = call_594819.call(nil, nil, nil, nil, body_594820)

var getDatabase* = Call_GetDatabase_594806(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_594807,
                                        base: "/", url: url_GetDatabase_594808,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_594821 = ref object of OpenApiRestCall_593437
proc url_GetDatabases_594823(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabases_594822(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594824 = query.getOrDefault("NextToken")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "NextToken", valid_594824
  var valid_594825 = query.getOrDefault("MaxResults")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "MaxResults", valid_594825
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594826 = header.getOrDefault("X-Amz-Date")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Date", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Security-Token")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Security-Token", valid_594827
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594828 = header.getOrDefault("X-Amz-Target")
  valid_594828 = validateParameter(valid_594828, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_594828 != nil:
    section.add "X-Amz-Target", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Content-Sha256", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Algorithm")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Algorithm", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Signature")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Signature", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-SignedHeaders", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Credential")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Credential", valid_594833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594835: Call_GetDatabases_594821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_594835.validator(path, query, header, formData, body)
  let scheme = call_594835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594835.url(scheme.get, call_594835.host, call_594835.base,
                         call_594835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594835, url, valid)

proc call*(call_594836: Call_GetDatabases_594821; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594837 = newJObject()
  var body_594838 = newJObject()
  add(query_594837, "NextToken", newJString(NextToken))
  if body != nil:
    body_594838 = body
  add(query_594837, "MaxResults", newJString(MaxResults))
  result = call_594836.call(nil, query_594837, nil, nil, body_594838)

var getDatabases* = Call_GetDatabases_594821(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_594822, base: "/", url: url_GetDatabases_594823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_594839 = ref object of OpenApiRestCall_593437
proc url_GetDataflowGraph_594841(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataflowGraph_594840(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594842 = header.getOrDefault("X-Amz-Date")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Date", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Security-Token")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Security-Token", valid_594843
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594844 = header.getOrDefault("X-Amz-Target")
  valid_594844 = validateParameter(valid_594844, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_594844 != nil:
    section.add "X-Amz-Target", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Content-Sha256", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Algorithm")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Algorithm", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Signature")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Signature", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-SignedHeaders", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Credential")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Credential", valid_594849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594851: Call_GetDataflowGraph_594839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_594851.validator(path, query, header, formData, body)
  let scheme = call_594851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594851.url(scheme.get, call_594851.host, call_594851.base,
                         call_594851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594851, url, valid)

proc call*(call_594852: Call_GetDataflowGraph_594839; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_594853 = newJObject()
  if body != nil:
    body_594853 = body
  result = call_594852.call(nil, nil, nil, nil, body_594853)

var getDataflowGraph* = Call_GetDataflowGraph_594839(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_594840, base: "/",
    url: url_GetDataflowGraph_594841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_594854 = ref object of OpenApiRestCall_593437
proc url_GetDevEndpoint_594856(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoint_594855(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594857 = header.getOrDefault("X-Amz-Date")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Date", valid_594857
  var valid_594858 = header.getOrDefault("X-Amz-Security-Token")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-Security-Token", valid_594858
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594859 = header.getOrDefault("X-Amz-Target")
  valid_594859 = validateParameter(valid_594859, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_594859 != nil:
    section.add "X-Amz-Target", valid_594859
  var valid_594860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "X-Amz-Content-Sha256", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-Algorithm")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Algorithm", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-Signature")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-Signature", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-SignedHeaders", valid_594863
  var valid_594864 = header.getOrDefault("X-Amz-Credential")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-Credential", valid_594864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594866: Call_GetDevEndpoint_594854; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_594866.validator(path, query, header, formData, body)
  let scheme = call_594866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594866.url(scheme.get, call_594866.host, call_594866.base,
                         call_594866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594866, url, valid)

proc call*(call_594867: Call_GetDevEndpoint_594854; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_594868 = newJObject()
  if body != nil:
    body_594868 = body
  result = call_594867.call(nil, nil, nil, nil, body_594868)

var getDevEndpoint* = Call_GetDevEndpoint_594854(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_594855, base: "/", url: url_GetDevEndpoint_594856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_594869 = ref object of OpenApiRestCall_593437
proc url_GetDevEndpoints_594871(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoints_594870(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594872 = query.getOrDefault("NextToken")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "NextToken", valid_594872
  var valid_594873 = query.getOrDefault("MaxResults")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "MaxResults", valid_594873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594874 = header.getOrDefault("X-Amz-Date")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "X-Amz-Date", valid_594874
  var valid_594875 = header.getOrDefault("X-Amz-Security-Token")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Security-Token", valid_594875
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594876 = header.getOrDefault("X-Amz-Target")
  valid_594876 = validateParameter(valid_594876, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_594876 != nil:
    section.add "X-Amz-Target", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-Content-Sha256", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Algorithm")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Algorithm", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-Signature")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-Signature", valid_594879
  var valid_594880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-SignedHeaders", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-Credential")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Credential", valid_594881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594883: Call_GetDevEndpoints_594869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_594883.validator(path, query, header, formData, body)
  let scheme = call_594883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594883.url(scheme.get, call_594883.host, call_594883.base,
                         call_594883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594883, url, valid)

proc call*(call_594884: Call_GetDevEndpoints_594869; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594885 = newJObject()
  var body_594886 = newJObject()
  add(query_594885, "NextToken", newJString(NextToken))
  if body != nil:
    body_594886 = body
  add(query_594885, "MaxResults", newJString(MaxResults))
  result = call_594884.call(nil, query_594885, nil, nil, body_594886)

var getDevEndpoints* = Call_GetDevEndpoints_594869(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_594870, base: "/", url: url_GetDevEndpoints_594871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_594887 = ref object of OpenApiRestCall_593437
proc url_GetJob_594889(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJob_594888(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an existing job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594890 = header.getOrDefault("X-Amz-Date")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Date", valid_594890
  var valid_594891 = header.getOrDefault("X-Amz-Security-Token")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Security-Token", valid_594891
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594892 = header.getOrDefault("X-Amz-Target")
  valid_594892 = validateParameter(valid_594892, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_594892 != nil:
    section.add "X-Amz-Target", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Content-Sha256", valid_594893
  var valid_594894 = header.getOrDefault("X-Amz-Algorithm")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-Algorithm", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-Signature")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-Signature", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-SignedHeaders", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Credential")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Credential", valid_594897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594899: Call_GetJob_594887; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_594899.validator(path, query, header, formData, body)
  let scheme = call_594899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594899.url(scheme.get, call_594899.host, call_594899.base,
                         call_594899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594899, url, valid)

proc call*(call_594900: Call_GetJob_594887; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_594901 = newJObject()
  if body != nil:
    body_594901 = body
  result = call_594900.call(nil, nil, nil, nil, body_594901)

var getJob* = Call_GetJob_594887(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_594888, base: "/",
                              url: url_GetJob_594889,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_594902 = ref object of OpenApiRestCall_593437
proc url_GetJobBookmark_594904(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobBookmark_594903(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information on a job bookmark entry.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594905 = header.getOrDefault("X-Amz-Date")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Date", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Security-Token")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Security-Token", valid_594906
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594907 = header.getOrDefault("X-Amz-Target")
  valid_594907 = validateParameter(valid_594907, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_594907 != nil:
    section.add "X-Amz-Target", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Content-Sha256", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-Algorithm")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Algorithm", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Signature")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Signature", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-SignedHeaders", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Credential")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Credential", valid_594912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594914: Call_GetJobBookmark_594902; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_594914.validator(path, query, header, formData, body)
  let scheme = call_594914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594914.url(scheme.get, call_594914.host, call_594914.base,
                         call_594914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594914, url, valid)

proc call*(call_594915: Call_GetJobBookmark_594902; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_594916 = newJObject()
  if body != nil:
    body_594916 = body
  result = call_594915.call(nil, nil, nil, nil, body_594916)

var getJobBookmark* = Call_GetJobBookmark_594902(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_594903, base: "/", url: url_GetJobBookmark_594904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_594917 = ref object of OpenApiRestCall_593437
proc url_GetJobRun_594919(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRun_594918(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given job run.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594920 = header.getOrDefault("X-Amz-Date")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Date", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Security-Token")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Security-Token", valid_594921
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594922 = header.getOrDefault("X-Amz-Target")
  valid_594922 = validateParameter(valid_594922, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_594922 != nil:
    section.add "X-Amz-Target", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Content-Sha256", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-Algorithm")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-Algorithm", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-Signature")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Signature", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-SignedHeaders", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Credential")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Credential", valid_594927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594929: Call_GetJobRun_594917; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_594929.validator(path, query, header, formData, body)
  let scheme = call_594929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594929.url(scheme.get, call_594929.host, call_594929.base,
                         call_594929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594929, url, valid)

proc call*(call_594930: Call_GetJobRun_594917; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_594931 = newJObject()
  if body != nil:
    body_594931 = body
  result = call_594930.call(nil, nil, nil, nil, body_594931)

var getJobRun* = Call_GetJobRun_594917(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_594918,
                                    base: "/", url: url_GetJobRun_594919,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_594932 = ref object of OpenApiRestCall_593437
proc url_GetJobRuns_594934(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRuns_594933(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594935 = query.getOrDefault("NextToken")
  valid_594935 = validateParameter(valid_594935, JString, required = false,
                                 default = nil)
  if valid_594935 != nil:
    section.add "NextToken", valid_594935
  var valid_594936 = query.getOrDefault("MaxResults")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "MaxResults", valid_594936
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594937 = header.getOrDefault("X-Amz-Date")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "X-Amz-Date", valid_594937
  var valid_594938 = header.getOrDefault("X-Amz-Security-Token")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "X-Amz-Security-Token", valid_594938
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594939 = header.getOrDefault("X-Amz-Target")
  valid_594939 = validateParameter(valid_594939, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_594939 != nil:
    section.add "X-Amz-Target", valid_594939
  var valid_594940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Content-Sha256", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Algorithm")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Algorithm", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Signature")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Signature", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-SignedHeaders", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Credential")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Credential", valid_594944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594946: Call_GetJobRuns_594932; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_594946.validator(path, query, header, formData, body)
  let scheme = call_594946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594946.url(scheme.get, call_594946.host, call_594946.base,
                         call_594946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594946, url, valid)

proc call*(call_594947: Call_GetJobRuns_594932; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594948 = newJObject()
  var body_594949 = newJObject()
  add(query_594948, "NextToken", newJString(NextToken))
  if body != nil:
    body_594949 = body
  add(query_594948, "MaxResults", newJString(MaxResults))
  result = call_594947.call(nil, query_594948, nil, nil, body_594949)

var getJobRuns* = Call_GetJobRuns_594932(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_594933,
                                      base: "/", url: url_GetJobRuns_594934,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_594950 = ref object of OpenApiRestCall_593437
proc url_GetJobs_594952(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobs_594951(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all current job definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594953 = query.getOrDefault("NextToken")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "NextToken", valid_594953
  var valid_594954 = query.getOrDefault("MaxResults")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "MaxResults", valid_594954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594955 = header.getOrDefault("X-Amz-Date")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Date", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Security-Token")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Security-Token", valid_594956
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594957 = header.getOrDefault("X-Amz-Target")
  valid_594957 = validateParameter(valid_594957, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_594957 != nil:
    section.add "X-Amz-Target", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Content-Sha256", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Algorithm")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Algorithm", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Signature")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Signature", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-SignedHeaders", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-Credential")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-Credential", valid_594962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594964: Call_GetJobs_594950; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_594964.validator(path, query, header, formData, body)
  let scheme = call_594964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594964.url(scheme.get, call_594964.host, call_594964.base,
                         call_594964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594964, url, valid)

proc call*(call_594965: Call_GetJobs_594950; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594966 = newJObject()
  var body_594967 = newJObject()
  add(query_594966, "NextToken", newJString(NextToken))
  if body != nil:
    body_594967 = body
  add(query_594966, "MaxResults", newJString(MaxResults))
  result = call_594965.call(nil, query_594966, nil, nil, body_594967)

var getJobs* = Call_GetJobs_594950(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_594951, base: "/",
                                url: url_GetJobs_594952,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_594968 = ref object of OpenApiRestCall_593437
proc url_GetMLTaskRun_594970(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRun_594969(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594971 = header.getOrDefault("X-Amz-Date")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Date", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Security-Token")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Security-Token", valid_594972
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594973 = header.getOrDefault("X-Amz-Target")
  valid_594973 = validateParameter(valid_594973, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_594973 != nil:
    section.add "X-Amz-Target", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Content-Sha256", valid_594974
  var valid_594975 = header.getOrDefault("X-Amz-Algorithm")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Algorithm", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Signature")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Signature", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-SignedHeaders", valid_594977
  var valid_594978 = header.getOrDefault("X-Amz-Credential")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "X-Amz-Credential", valid_594978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594980: Call_GetMLTaskRun_594968; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_594980.validator(path, query, header, formData, body)
  let scheme = call_594980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594980.url(scheme.get, call_594980.host, call_594980.base,
                         call_594980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594980, url, valid)

proc call*(call_594981: Call_GetMLTaskRun_594968; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_594982 = newJObject()
  if body != nil:
    body_594982 = body
  result = call_594981.call(nil, nil, nil, nil, body_594982)

var getMLTaskRun* = Call_GetMLTaskRun_594968(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_594969, base: "/", url: url_GetMLTaskRun_594970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_594983 = ref object of OpenApiRestCall_593437
proc url_GetMLTaskRuns_594985(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRuns_594984(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594986 = query.getOrDefault("NextToken")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "NextToken", valid_594986
  var valid_594987 = query.getOrDefault("MaxResults")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "MaxResults", valid_594987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594988 = header.getOrDefault("X-Amz-Date")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "X-Amz-Date", valid_594988
  var valid_594989 = header.getOrDefault("X-Amz-Security-Token")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Security-Token", valid_594989
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594990 = header.getOrDefault("X-Amz-Target")
  valid_594990 = validateParameter(valid_594990, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_594990 != nil:
    section.add "X-Amz-Target", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Content-Sha256", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-Algorithm")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Algorithm", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-Signature")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-Signature", valid_594993
  var valid_594994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-SignedHeaders", valid_594994
  var valid_594995 = header.getOrDefault("X-Amz-Credential")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "X-Amz-Credential", valid_594995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594997: Call_GetMLTaskRuns_594983; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_594997.validator(path, query, header, formData, body)
  let scheme = call_594997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594997.url(scheme.get, call_594997.host, call_594997.base,
                         call_594997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594997, url, valid)

proc call*(call_594998: Call_GetMLTaskRuns_594983; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594999 = newJObject()
  var body_595000 = newJObject()
  add(query_594999, "NextToken", newJString(NextToken))
  if body != nil:
    body_595000 = body
  add(query_594999, "MaxResults", newJString(MaxResults))
  result = call_594998.call(nil, query_594999, nil, nil, body_595000)

var getMLTaskRuns* = Call_GetMLTaskRuns_594983(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_594984, base: "/", url: url_GetMLTaskRuns_594985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_595001 = ref object of OpenApiRestCall_593437
proc url_GetMLTransform_595003(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransform_595002(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595004 = header.getOrDefault("X-Amz-Date")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "X-Amz-Date", valid_595004
  var valid_595005 = header.getOrDefault("X-Amz-Security-Token")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-Security-Token", valid_595005
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595006 = header.getOrDefault("X-Amz-Target")
  valid_595006 = validateParameter(valid_595006, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_595006 != nil:
    section.add "X-Amz-Target", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Content-Sha256", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-Algorithm")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-Algorithm", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Signature")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Signature", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-SignedHeaders", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Credential")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Credential", valid_595011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595013: Call_GetMLTransform_595001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_595013.validator(path, query, header, formData, body)
  let scheme = call_595013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595013.url(scheme.get, call_595013.host, call_595013.base,
                         call_595013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595013, url, valid)

proc call*(call_595014: Call_GetMLTransform_595001; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_595015 = newJObject()
  if body != nil:
    body_595015 = body
  result = call_595014.call(nil, nil, nil, nil, body_595015)

var getMLTransform* = Call_GetMLTransform_595001(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_595002, base: "/", url: url_GetMLTransform_595003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_595016 = ref object of OpenApiRestCall_593437
proc url_GetMLTransforms_595018(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransforms_595017(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595019 = query.getOrDefault("NextToken")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "NextToken", valid_595019
  var valid_595020 = query.getOrDefault("MaxResults")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "MaxResults", valid_595020
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595021 = header.getOrDefault("X-Amz-Date")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Date", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-Security-Token")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-Security-Token", valid_595022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595023 = header.getOrDefault("X-Amz-Target")
  valid_595023 = validateParameter(valid_595023, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_595023 != nil:
    section.add "X-Amz-Target", valid_595023
  var valid_595024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "X-Amz-Content-Sha256", valid_595024
  var valid_595025 = header.getOrDefault("X-Amz-Algorithm")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "X-Amz-Algorithm", valid_595025
  var valid_595026 = header.getOrDefault("X-Amz-Signature")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "X-Amz-Signature", valid_595026
  var valid_595027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "X-Amz-SignedHeaders", valid_595027
  var valid_595028 = header.getOrDefault("X-Amz-Credential")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "X-Amz-Credential", valid_595028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595030: Call_GetMLTransforms_595016; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_595030.validator(path, query, header, formData, body)
  let scheme = call_595030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595030.url(scheme.get, call_595030.host, call_595030.base,
                         call_595030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595030, url, valid)

proc call*(call_595031: Call_GetMLTransforms_595016; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595032 = newJObject()
  var body_595033 = newJObject()
  add(query_595032, "NextToken", newJString(NextToken))
  if body != nil:
    body_595033 = body
  add(query_595032, "MaxResults", newJString(MaxResults))
  result = call_595031.call(nil, query_595032, nil, nil, body_595033)

var getMLTransforms* = Call_GetMLTransforms_595016(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_595017, base: "/", url: url_GetMLTransforms_595018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_595034 = ref object of OpenApiRestCall_593437
proc url_GetMapping_595036(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMapping_595035(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates mappings.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595037 = header.getOrDefault("X-Amz-Date")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-Date", valid_595037
  var valid_595038 = header.getOrDefault("X-Amz-Security-Token")
  valid_595038 = validateParameter(valid_595038, JString, required = false,
                                 default = nil)
  if valid_595038 != nil:
    section.add "X-Amz-Security-Token", valid_595038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595039 = header.getOrDefault("X-Amz-Target")
  valid_595039 = validateParameter(valid_595039, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_595039 != nil:
    section.add "X-Amz-Target", valid_595039
  var valid_595040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "X-Amz-Content-Sha256", valid_595040
  var valid_595041 = header.getOrDefault("X-Amz-Algorithm")
  valid_595041 = validateParameter(valid_595041, JString, required = false,
                                 default = nil)
  if valid_595041 != nil:
    section.add "X-Amz-Algorithm", valid_595041
  var valid_595042 = header.getOrDefault("X-Amz-Signature")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "X-Amz-Signature", valid_595042
  var valid_595043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "X-Amz-SignedHeaders", valid_595043
  var valid_595044 = header.getOrDefault("X-Amz-Credential")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "X-Amz-Credential", valid_595044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595046: Call_GetMapping_595034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_595046.validator(path, query, header, formData, body)
  let scheme = call_595046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595046.url(scheme.get, call_595046.host, call_595046.base,
                         call_595046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595046, url, valid)

proc call*(call_595047: Call_GetMapping_595034; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_595048 = newJObject()
  if body != nil:
    body_595048 = body
  result = call_595047.call(nil, nil, nil, nil, body_595048)

var getMapping* = Call_GetMapping_595034(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_595035,
                                      base: "/", url: url_GetMapping_595036,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_595049 = ref object of OpenApiRestCall_593437
proc url_GetPartition_595051(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartition_595050(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595052 = header.getOrDefault("X-Amz-Date")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Date", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Security-Token")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Security-Token", valid_595053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595054 = header.getOrDefault("X-Amz-Target")
  valid_595054 = validateParameter(valid_595054, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_595054 != nil:
    section.add "X-Amz-Target", valid_595054
  var valid_595055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "X-Amz-Content-Sha256", valid_595055
  var valid_595056 = header.getOrDefault("X-Amz-Algorithm")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = nil)
  if valid_595056 != nil:
    section.add "X-Amz-Algorithm", valid_595056
  var valid_595057 = header.getOrDefault("X-Amz-Signature")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "X-Amz-Signature", valid_595057
  var valid_595058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "X-Amz-SignedHeaders", valid_595058
  var valid_595059 = header.getOrDefault("X-Amz-Credential")
  valid_595059 = validateParameter(valid_595059, JString, required = false,
                                 default = nil)
  if valid_595059 != nil:
    section.add "X-Amz-Credential", valid_595059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595061: Call_GetPartition_595049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_595061.validator(path, query, header, formData, body)
  let scheme = call_595061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595061.url(scheme.get, call_595061.host, call_595061.base,
                         call_595061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595061, url, valid)

proc call*(call_595062: Call_GetPartition_595049; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_595063 = newJObject()
  if body != nil:
    body_595063 = body
  result = call_595062.call(nil, nil, nil, nil, body_595063)

var getPartition* = Call_GetPartition_595049(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_595050, base: "/", url: url_GetPartition_595051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_595064 = ref object of OpenApiRestCall_593437
proc url_GetPartitions_595066(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartitions_595065(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the partitions in a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595067 = query.getOrDefault("NextToken")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "NextToken", valid_595067
  var valid_595068 = query.getOrDefault("MaxResults")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "MaxResults", valid_595068
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595069 = header.getOrDefault("X-Amz-Date")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-Date", valid_595069
  var valid_595070 = header.getOrDefault("X-Amz-Security-Token")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Security-Token", valid_595070
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595071 = header.getOrDefault("X-Amz-Target")
  valid_595071 = validateParameter(valid_595071, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_595071 != nil:
    section.add "X-Amz-Target", valid_595071
  var valid_595072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-Content-Sha256", valid_595072
  var valid_595073 = header.getOrDefault("X-Amz-Algorithm")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "X-Amz-Algorithm", valid_595073
  var valid_595074 = header.getOrDefault("X-Amz-Signature")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "X-Amz-Signature", valid_595074
  var valid_595075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "X-Amz-SignedHeaders", valid_595075
  var valid_595076 = header.getOrDefault("X-Amz-Credential")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Credential", valid_595076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595078: Call_GetPartitions_595064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_595078.validator(path, query, header, formData, body)
  let scheme = call_595078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595078.url(scheme.get, call_595078.host, call_595078.base,
                         call_595078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595078, url, valid)

proc call*(call_595079: Call_GetPartitions_595064; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595080 = newJObject()
  var body_595081 = newJObject()
  add(query_595080, "NextToken", newJString(NextToken))
  if body != nil:
    body_595081 = body
  add(query_595080, "MaxResults", newJString(MaxResults))
  result = call_595079.call(nil, query_595080, nil, nil, body_595081)

var getPartitions* = Call_GetPartitions_595064(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_595065, base: "/", url: url_GetPartitions_595066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_595082 = ref object of OpenApiRestCall_593437
proc url_GetPlan_595084(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPlan_595083(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets code to perform a specified mapping.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595085 = header.getOrDefault("X-Amz-Date")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Date", valid_595085
  var valid_595086 = header.getOrDefault("X-Amz-Security-Token")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-Security-Token", valid_595086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595087 = header.getOrDefault("X-Amz-Target")
  valid_595087 = validateParameter(valid_595087, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_595087 != nil:
    section.add "X-Amz-Target", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Content-Sha256", valid_595088
  var valid_595089 = header.getOrDefault("X-Amz-Algorithm")
  valid_595089 = validateParameter(valid_595089, JString, required = false,
                                 default = nil)
  if valid_595089 != nil:
    section.add "X-Amz-Algorithm", valid_595089
  var valid_595090 = header.getOrDefault("X-Amz-Signature")
  valid_595090 = validateParameter(valid_595090, JString, required = false,
                                 default = nil)
  if valid_595090 != nil:
    section.add "X-Amz-Signature", valid_595090
  var valid_595091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-SignedHeaders", valid_595091
  var valid_595092 = header.getOrDefault("X-Amz-Credential")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "X-Amz-Credential", valid_595092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595094: Call_GetPlan_595082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_595094.validator(path, query, header, formData, body)
  let scheme = call_595094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595094.url(scheme.get, call_595094.host, call_595094.base,
                         call_595094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595094, url, valid)

proc call*(call_595095: Call_GetPlan_595082; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_595096 = newJObject()
  if body != nil:
    body_595096 = body
  result = call_595095.call(nil, nil, nil, nil, body_595096)

var getPlan* = Call_GetPlan_595082(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_595083, base: "/",
                                url: url_GetPlan_595084,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_595097 = ref object of OpenApiRestCall_593437
proc url_GetResourcePolicy_595099(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourcePolicy_595098(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a specified resource policy.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595100 = header.getOrDefault("X-Amz-Date")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Date", valid_595100
  var valid_595101 = header.getOrDefault("X-Amz-Security-Token")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-Security-Token", valid_595101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595102 = header.getOrDefault("X-Amz-Target")
  valid_595102 = validateParameter(valid_595102, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_595102 != nil:
    section.add "X-Amz-Target", valid_595102
  var valid_595103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595103 = validateParameter(valid_595103, JString, required = false,
                                 default = nil)
  if valid_595103 != nil:
    section.add "X-Amz-Content-Sha256", valid_595103
  var valid_595104 = header.getOrDefault("X-Amz-Algorithm")
  valid_595104 = validateParameter(valid_595104, JString, required = false,
                                 default = nil)
  if valid_595104 != nil:
    section.add "X-Amz-Algorithm", valid_595104
  var valid_595105 = header.getOrDefault("X-Amz-Signature")
  valid_595105 = validateParameter(valid_595105, JString, required = false,
                                 default = nil)
  if valid_595105 != nil:
    section.add "X-Amz-Signature", valid_595105
  var valid_595106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595106 = validateParameter(valid_595106, JString, required = false,
                                 default = nil)
  if valid_595106 != nil:
    section.add "X-Amz-SignedHeaders", valid_595106
  var valid_595107 = header.getOrDefault("X-Amz-Credential")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "X-Amz-Credential", valid_595107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595109: Call_GetResourcePolicy_595097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_595109.validator(path, query, header, formData, body)
  let scheme = call_595109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595109.url(scheme.get, call_595109.host, call_595109.base,
                         call_595109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595109, url, valid)

proc call*(call_595110: Call_GetResourcePolicy_595097; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_595111 = newJObject()
  if body != nil:
    body_595111 = body
  result = call_595110.call(nil, nil, nil, nil, body_595111)

var getResourcePolicy* = Call_GetResourcePolicy_595097(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_595098, base: "/",
    url: url_GetResourcePolicy_595099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_595112 = ref object of OpenApiRestCall_593437
proc url_GetSecurityConfiguration_595114(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfiguration_595113(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified security configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595115 = header.getOrDefault("X-Amz-Date")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Date", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-Security-Token")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-Security-Token", valid_595116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595117 = header.getOrDefault("X-Amz-Target")
  valid_595117 = validateParameter(valid_595117, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_595117 != nil:
    section.add "X-Amz-Target", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-Content-Sha256", valid_595118
  var valid_595119 = header.getOrDefault("X-Amz-Algorithm")
  valid_595119 = validateParameter(valid_595119, JString, required = false,
                                 default = nil)
  if valid_595119 != nil:
    section.add "X-Amz-Algorithm", valid_595119
  var valid_595120 = header.getOrDefault("X-Amz-Signature")
  valid_595120 = validateParameter(valid_595120, JString, required = false,
                                 default = nil)
  if valid_595120 != nil:
    section.add "X-Amz-Signature", valid_595120
  var valid_595121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "X-Amz-SignedHeaders", valid_595121
  var valid_595122 = header.getOrDefault("X-Amz-Credential")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "X-Amz-Credential", valid_595122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595124: Call_GetSecurityConfiguration_595112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_595124.validator(path, query, header, formData, body)
  let scheme = call_595124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595124.url(scheme.get, call_595124.host, call_595124.base,
                         call_595124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595124, url, valid)

proc call*(call_595125: Call_GetSecurityConfiguration_595112; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_595126 = newJObject()
  if body != nil:
    body_595126 = body
  result = call_595125.call(nil, nil, nil, nil, body_595126)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_595112(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_595113, base: "/",
    url: url_GetSecurityConfiguration_595114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_595127 = ref object of OpenApiRestCall_593437
proc url_GetSecurityConfigurations_595129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfigurations_595128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of all security configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595130 = query.getOrDefault("NextToken")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "NextToken", valid_595130
  var valid_595131 = query.getOrDefault("MaxResults")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "MaxResults", valid_595131
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595132 = header.getOrDefault("X-Amz-Date")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-Date", valid_595132
  var valid_595133 = header.getOrDefault("X-Amz-Security-Token")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Security-Token", valid_595133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595134 = header.getOrDefault("X-Amz-Target")
  valid_595134 = validateParameter(valid_595134, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_595134 != nil:
    section.add "X-Amz-Target", valid_595134
  var valid_595135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595135 = validateParameter(valid_595135, JString, required = false,
                                 default = nil)
  if valid_595135 != nil:
    section.add "X-Amz-Content-Sha256", valid_595135
  var valid_595136 = header.getOrDefault("X-Amz-Algorithm")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "X-Amz-Algorithm", valid_595136
  var valid_595137 = header.getOrDefault("X-Amz-Signature")
  valid_595137 = validateParameter(valid_595137, JString, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "X-Amz-Signature", valid_595137
  var valid_595138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595138 = validateParameter(valid_595138, JString, required = false,
                                 default = nil)
  if valid_595138 != nil:
    section.add "X-Amz-SignedHeaders", valid_595138
  var valid_595139 = header.getOrDefault("X-Amz-Credential")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "X-Amz-Credential", valid_595139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595141: Call_GetSecurityConfigurations_595127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_595141.validator(path, query, header, formData, body)
  let scheme = call_595141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595141.url(scheme.get, call_595141.host, call_595141.base,
                         call_595141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595141, url, valid)

proc call*(call_595142: Call_GetSecurityConfigurations_595127; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595143 = newJObject()
  var body_595144 = newJObject()
  add(query_595143, "NextToken", newJString(NextToken))
  if body != nil:
    body_595144 = body
  add(query_595143, "MaxResults", newJString(MaxResults))
  result = call_595142.call(nil, query_595143, nil, nil, body_595144)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_595127(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_595128, base: "/",
    url: url_GetSecurityConfigurations_595129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_595145 = ref object of OpenApiRestCall_593437
proc url_GetTable_595147(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTable_595146(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595148 = header.getOrDefault("X-Amz-Date")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Date", valid_595148
  var valid_595149 = header.getOrDefault("X-Amz-Security-Token")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "X-Amz-Security-Token", valid_595149
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595150 = header.getOrDefault("X-Amz-Target")
  valid_595150 = validateParameter(valid_595150, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_595150 != nil:
    section.add "X-Amz-Target", valid_595150
  var valid_595151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "X-Amz-Content-Sha256", valid_595151
  var valid_595152 = header.getOrDefault("X-Amz-Algorithm")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "X-Amz-Algorithm", valid_595152
  var valid_595153 = header.getOrDefault("X-Amz-Signature")
  valid_595153 = validateParameter(valid_595153, JString, required = false,
                                 default = nil)
  if valid_595153 != nil:
    section.add "X-Amz-Signature", valid_595153
  var valid_595154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "X-Amz-SignedHeaders", valid_595154
  var valid_595155 = header.getOrDefault("X-Amz-Credential")
  valid_595155 = validateParameter(valid_595155, JString, required = false,
                                 default = nil)
  if valid_595155 != nil:
    section.add "X-Amz-Credential", valid_595155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595157: Call_GetTable_595145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_595157.validator(path, query, header, formData, body)
  let scheme = call_595157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595157.url(scheme.get, call_595157.host, call_595157.base,
                         call_595157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595157, url, valid)

proc call*(call_595158: Call_GetTable_595145; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_595159 = newJObject()
  if body != nil:
    body_595159 = body
  result = call_595158.call(nil, nil, nil, nil, body_595159)

var getTable* = Call_GetTable_595145(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_595146, base: "/",
                                  url: url_GetTable_595147,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_595160 = ref object of OpenApiRestCall_593437
proc url_GetTableVersion_595162(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersion_595161(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a specified version of a table.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595163 = header.getOrDefault("X-Amz-Date")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Date", valid_595163
  var valid_595164 = header.getOrDefault("X-Amz-Security-Token")
  valid_595164 = validateParameter(valid_595164, JString, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "X-Amz-Security-Token", valid_595164
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595165 = header.getOrDefault("X-Amz-Target")
  valid_595165 = validateParameter(valid_595165, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_595165 != nil:
    section.add "X-Amz-Target", valid_595165
  var valid_595166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "X-Amz-Content-Sha256", valid_595166
  var valid_595167 = header.getOrDefault("X-Amz-Algorithm")
  valid_595167 = validateParameter(valid_595167, JString, required = false,
                                 default = nil)
  if valid_595167 != nil:
    section.add "X-Amz-Algorithm", valid_595167
  var valid_595168 = header.getOrDefault("X-Amz-Signature")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "X-Amz-Signature", valid_595168
  var valid_595169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "X-Amz-SignedHeaders", valid_595169
  var valid_595170 = header.getOrDefault("X-Amz-Credential")
  valid_595170 = validateParameter(valid_595170, JString, required = false,
                                 default = nil)
  if valid_595170 != nil:
    section.add "X-Amz-Credential", valid_595170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595172: Call_GetTableVersion_595160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_595172.validator(path, query, header, formData, body)
  let scheme = call_595172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595172.url(scheme.get, call_595172.host, call_595172.base,
                         call_595172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595172, url, valid)

proc call*(call_595173: Call_GetTableVersion_595160; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_595174 = newJObject()
  if body != nil:
    body_595174 = body
  result = call_595173.call(nil, nil, nil, nil, body_595174)

var getTableVersion* = Call_GetTableVersion_595160(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_595161, base: "/", url: url_GetTableVersion_595162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_595175 = ref object of OpenApiRestCall_593437
proc url_GetTableVersions_595177(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersions_595176(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595178 = query.getOrDefault("NextToken")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "NextToken", valid_595178
  var valid_595179 = query.getOrDefault("MaxResults")
  valid_595179 = validateParameter(valid_595179, JString, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "MaxResults", valid_595179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595180 = header.getOrDefault("X-Amz-Date")
  valid_595180 = validateParameter(valid_595180, JString, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "X-Amz-Date", valid_595180
  var valid_595181 = header.getOrDefault("X-Amz-Security-Token")
  valid_595181 = validateParameter(valid_595181, JString, required = false,
                                 default = nil)
  if valid_595181 != nil:
    section.add "X-Amz-Security-Token", valid_595181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595182 = header.getOrDefault("X-Amz-Target")
  valid_595182 = validateParameter(valid_595182, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_595182 != nil:
    section.add "X-Amz-Target", valid_595182
  var valid_595183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "X-Amz-Content-Sha256", valid_595183
  var valid_595184 = header.getOrDefault("X-Amz-Algorithm")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-Algorithm", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-Signature")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-Signature", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-SignedHeaders", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Credential")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Credential", valid_595187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595189: Call_GetTableVersions_595175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_595189.validator(path, query, header, formData, body)
  let scheme = call_595189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595189.url(scheme.get, call_595189.host, call_595189.base,
                         call_595189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595189, url, valid)

proc call*(call_595190: Call_GetTableVersions_595175; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595191 = newJObject()
  var body_595192 = newJObject()
  add(query_595191, "NextToken", newJString(NextToken))
  if body != nil:
    body_595192 = body
  add(query_595191, "MaxResults", newJString(MaxResults))
  result = call_595190.call(nil, query_595191, nil, nil, body_595192)

var getTableVersions* = Call_GetTableVersions_595175(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_595176, base: "/",
    url: url_GetTableVersions_595177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_595193 = ref object of OpenApiRestCall_593437
proc url_GetTables_595195(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTables_595194(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595196 = query.getOrDefault("NextToken")
  valid_595196 = validateParameter(valid_595196, JString, required = false,
                                 default = nil)
  if valid_595196 != nil:
    section.add "NextToken", valid_595196
  var valid_595197 = query.getOrDefault("MaxResults")
  valid_595197 = validateParameter(valid_595197, JString, required = false,
                                 default = nil)
  if valid_595197 != nil:
    section.add "MaxResults", valid_595197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595198 = header.getOrDefault("X-Amz-Date")
  valid_595198 = validateParameter(valid_595198, JString, required = false,
                                 default = nil)
  if valid_595198 != nil:
    section.add "X-Amz-Date", valid_595198
  var valid_595199 = header.getOrDefault("X-Amz-Security-Token")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "X-Amz-Security-Token", valid_595199
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595200 = header.getOrDefault("X-Amz-Target")
  valid_595200 = validateParameter(valid_595200, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_595200 != nil:
    section.add "X-Amz-Target", valid_595200
  var valid_595201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Content-Sha256", valid_595201
  var valid_595202 = header.getOrDefault("X-Amz-Algorithm")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Algorithm", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-Signature")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-Signature", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-SignedHeaders", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Credential")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Credential", valid_595205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595207: Call_GetTables_595193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_595207.validator(path, query, header, formData, body)
  let scheme = call_595207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595207.url(scheme.get, call_595207.host, call_595207.base,
                         call_595207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595207, url, valid)

proc call*(call_595208: Call_GetTables_595193; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595209 = newJObject()
  var body_595210 = newJObject()
  add(query_595209, "NextToken", newJString(NextToken))
  if body != nil:
    body_595210 = body
  add(query_595209, "MaxResults", newJString(MaxResults))
  result = call_595208.call(nil, query_595209, nil, nil, body_595210)

var getTables* = Call_GetTables_595193(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_595194,
                                    base: "/", url: url_GetTables_595195,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_595211 = ref object of OpenApiRestCall_593437
proc url_GetTags_595213(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTags_595212(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of tags associated with a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595214 = header.getOrDefault("X-Amz-Date")
  valid_595214 = validateParameter(valid_595214, JString, required = false,
                                 default = nil)
  if valid_595214 != nil:
    section.add "X-Amz-Date", valid_595214
  var valid_595215 = header.getOrDefault("X-Amz-Security-Token")
  valid_595215 = validateParameter(valid_595215, JString, required = false,
                                 default = nil)
  if valid_595215 != nil:
    section.add "X-Amz-Security-Token", valid_595215
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595216 = header.getOrDefault("X-Amz-Target")
  valid_595216 = validateParameter(valid_595216, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_595216 != nil:
    section.add "X-Amz-Target", valid_595216
  var valid_595217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Content-Sha256", valid_595217
  var valid_595218 = header.getOrDefault("X-Amz-Algorithm")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "X-Amz-Algorithm", valid_595218
  var valid_595219 = header.getOrDefault("X-Amz-Signature")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "X-Amz-Signature", valid_595219
  var valid_595220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-SignedHeaders", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Credential")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Credential", valid_595221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595223: Call_GetTags_595211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_595223.validator(path, query, header, formData, body)
  let scheme = call_595223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595223.url(scheme.get, call_595223.host, call_595223.base,
                         call_595223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595223, url, valid)

proc call*(call_595224: Call_GetTags_595211; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_595225 = newJObject()
  if body != nil:
    body_595225 = body
  result = call_595224.call(nil, nil, nil, nil, body_595225)

var getTags* = Call_GetTags_595211(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_595212, base: "/",
                                url: url_GetTags_595213,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_595226 = ref object of OpenApiRestCall_593437
proc url_GetTrigger_595228(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTrigger_595227(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a trigger.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595229 = header.getOrDefault("X-Amz-Date")
  valid_595229 = validateParameter(valid_595229, JString, required = false,
                                 default = nil)
  if valid_595229 != nil:
    section.add "X-Amz-Date", valid_595229
  var valid_595230 = header.getOrDefault("X-Amz-Security-Token")
  valid_595230 = validateParameter(valid_595230, JString, required = false,
                                 default = nil)
  if valid_595230 != nil:
    section.add "X-Amz-Security-Token", valid_595230
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595231 = header.getOrDefault("X-Amz-Target")
  valid_595231 = validateParameter(valid_595231, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_595231 != nil:
    section.add "X-Amz-Target", valid_595231
  var valid_595232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595232 = validateParameter(valid_595232, JString, required = false,
                                 default = nil)
  if valid_595232 != nil:
    section.add "X-Amz-Content-Sha256", valid_595232
  var valid_595233 = header.getOrDefault("X-Amz-Algorithm")
  valid_595233 = validateParameter(valid_595233, JString, required = false,
                                 default = nil)
  if valid_595233 != nil:
    section.add "X-Amz-Algorithm", valid_595233
  var valid_595234 = header.getOrDefault("X-Amz-Signature")
  valid_595234 = validateParameter(valid_595234, JString, required = false,
                                 default = nil)
  if valid_595234 != nil:
    section.add "X-Amz-Signature", valid_595234
  var valid_595235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595235 = validateParameter(valid_595235, JString, required = false,
                                 default = nil)
  if valid_595235 != nil:
    section.add "X-Amz-SignedHeaders", valid_595235
  var valid_595236 = header.getOrDefault("X-Amz-Credential")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Credential", valid_595236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595238: Call_GetTrigger_595226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_595238.validator(path, query, header, formData, body)
  let scheme = call_595238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595238.url(scheme.get, call_595238.host, call_595238.base,
                         call_595238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595238, url, valid)

proc call*(call_595239: Call_GetTrigger_595226; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_595240 = newJObject()
  if body != nil:
    body_595240 = body
  result = call_595239.call(nil, nil, nil, nil, body_595240)

var getTrigger* = Call_GetTrigger_595226(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_595227,
                                      base: "/", url: url_GetTrigger_595228,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_595241 = ref object of OpenApiRestCall_593437
proc url_GetTriggers_595243(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTriggers_595242(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the triggers associated with a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595244 = query.getOrDefault("NextToken")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "NextToken", valid_595244
  var valid_595245 = query.getOrDefault("MaxResults")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "MaxResults", valid_595245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595246 = header.getOrDefault("X-Amz-Date")
  valid_595246 = validateParameter(valid_595246, JString, required = false,
                                 default = nil)
  if valid_595246 != nil:
    section.add "X-Amz-Date", valid_595246
  var valid_595247 = header.getOrDefault("X-Amz-Security-Token")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "X-Amz-Security-Token", valid_595247
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595248 = header.getOrDefault("X-Amz-Target")
  valid_595248 = validateParameter(valid_595248, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_595248 != nil:
    section.add "X-Amz-Target", valid_595248
  var valid_595249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "X-Amz-Content-Sha256", valid_595249
  var valid_595250 = header.getOrDefault("X-Amz-Algorithm")
  valid_595250 = validateParameter(valid_595250, JString, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "X-Amz-Algorithm", valid_595250
  var valid_595251 = header.getOrDefault("X-Amz-Signature")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Signature", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-SignedHeaders", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Credential")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Credential", valid_595253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595255: Call_GetTriggers_595241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_595255.validator(path, query, header, formData, body)
  let scheme = call_595255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595255.url(scheme.get, call_595255.host, call_595255.base,
                         call_595255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595255, url, valid)

proc call*(call_595256: Call_GetTriggers_595241; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595257 = newJObject()
  var body_595258 = newJObject()
  add(query_595257, "NextToken", newJString(NextToken))
  if body != nil:
    body_595258 = body
  add(query_595257, "MaxResults", newJString(MaxResults))
  result = call_595256.call(nil, query_595257, nil, nil, body_595258)

var getTriggers* = Call_GetTriggers_595241(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_595242,
                                        base: "/", url: url_GetTriggers_595243,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_595259 = ref object of OpenApiRestCall_593437
proc url_GetUserDefinedFunction_595261(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunction_595260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified function definition from the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595262 = header.getOrDefault("X-Amz-Date")
  valid_595262 = validateParameter(valid_595262, JString, required = false,
                                 default = nil)
  if valid_595262 != nil:
    section.add "X-Amz-Date", valid_595262
  var valid_595263 = header.getOrDefault("X-Amz-Security-Token")
  valid_595263 = validateParameter(valid_595263, JString, required = false,
                                 default = nil)
  if valid_595263 != nil:
    section.add "X-Amz-Security-Token", valid_595263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595264 = header.getOrDefault("X-Amz-Target")
  valid_595264 = validateParameter(valid_595264, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_595264 != nil:
    section.add "X-Amz-Target", valid_595264
  var valid_595265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595265 = validateParameter(valid_595265, JString, required = false,
                                 default = nil)
  if valid_595265 != nil:
    section.add "X-Amz-Content-Sha256", valid_595265
  var valid_595266 = header.getOrDefault("X-Amz-Algorithm")
  valid_595266 = validateParameter(valid_595266, JString, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "X-Amz-Algorithm", valid_595266
  var valid_595267 = header.getOrDefault("X-Amz-Signature")
  valid_595267 = validateParameter(valid_595267, JString, required = false,
                                 default = nil)
  if valid_595267 != nil:
    section.add "X-Amz-Signature", valid_595267
  var valid_595268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595268 = validateParameter(valid_595268, JString, required = false,
                                 default = nil)
  if valid_595268 != nil:
    section.add "X-Amz-SignedHeaders", valid_595268
  var valid_595269 = header.getOrDefault("X-Amz-Credential")
  valid_595269 = validateParameter(valid_595269, JString, required = false,
                                 default = nil)
  if valid_595269 != nil:
    section.add "X-Amz-Credential", valid_595269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595271: Call_GetUserDefinedFunction_595259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_595271.validator(path, query, header, formData, body)
  let scheme = call_595271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595271.url(scheme.get, call_595271.host, call_595271.base,
                         call_595271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595271, url, valid)

proc call*(call_595272: Call_GetUserDefinedFunction_595259; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_595273 = newJObject()
  if body != nil:
    body_595273 = body
  result = call_595272.call(nil, nil, nil, nil, body_595273)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_595259(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_595260, base: "/",
    url: url_GetUserDefinedFunction_595261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_595274 = ref object of OpenApiRestCall_593437
proc url_GetUserDefinedFunctions_595276(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunctions_595275(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595277 = query.getOrDefault("NextToken")
  valid_595277 = validateParameter(valid_595277, JString, required = false,
                                 default = nil)
  if valid_595277 != nil:
    section.add "NextToken", valid_595277
  var valid_595278 = query.getOrDefault("MaxResults")
  valid_595278 = validateParameter(valid_595278, JString, required = false,
                                 default = nil)
  if valid_595278 != nil:
    section.add "MaxResults", valid_595278
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595279 = header.getOrDefault("X-Amz-Date")
  valid_595279 = validateParameter(valid_595279, JString, required = false,
                                 default = nil)
  if valid_595279 != nil:
    section.add "X-Amz-Date", valid_595279
  var valid_595280 = header.getOrDefault("X-Amz-Security-Token")
  valid_595280 = validateParameter(valid_595280, JString, required = false,
                                 default = nil)
  if valid_595280 != nil:
    section.add "X-Amz-Security-Token", valid_595280
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595281 = header.getOrDefault("X-Amz-Target")
  valid_595281 = validateParameter(valid_595281, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_595281 != nil:
    section.add "X-Amz-Target", valid_595281
  var valid_595282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595282 = validateParameter(valid_595282, JString, required = false,
                                 default = nil)
  if valid_595282 != nil:
    section.add "X-Amz-Content-Sha256", valid_595282
  var valid_595283 = header.getOrDefault("X-Amz-Algorithm")
  valid_595283 = validateParameter(valid_595283, JString, required = false,
                                 default = nil)
  if valid_595283 != nil:
    section.add "X-Amz-Algorithm", valid_595283
  var valid_595284 = header.getOrDefault("X-Amz-Signature")
  valid_595284 = validateParameter(valid_595284, JString, required = false,
                                 default = nil)
  if valid_595284 != nil:
    section.add "X-Amz-Signature", valid_595284
  var valid_595285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-SignedHeaders", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Credential")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Credential", valid_595286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595288: Call_GetUserDefinedFunctions_595274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_595288.validator(path, query, header, formData, body)
  let scheme = call_595288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595288.url(scheme.get, call_595288.host, call_595288.base,
                         call_595288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595288, url, valid)

proc call*(call_595289: Call_GetUserDefinedFunctions_595274; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595290 = newJObject()
  var body_595291 = newJObject()
  add(query_595290, "NextToken", newJString(NextToken))
  if body != nil:
    body_595291 = body
  add(query_595290, "MaxResults", newJString(MaxResults))
  result = call_595289.call(nil, query_595290, nil, nil, body_595291)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_595274(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_595275, base: "/",
    url: url_GetUserDefinedFunctions_595276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_595292 = ref object of OpenApiRestCall_593437
proc url_GetWorkflow_595294(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflow_595293(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves resource metadata for a workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595295 = header.getOrDefault("X-Amz-Date")
  valid_595295 = validateParameter(valid_595295, JString, required = false,
                                 default = nil)
  if valid_595295 != nil:
    section.add "X-Amz-Date", valid_595295
  var valid_595296 = header.getOrDefault("X-Amz-Security-Token")
  valid_595296 = validateParameter(valid_595296, JString, required = false,
                                 default = nil)
  if valid_595296 != nil:
    section.add "X-Amz-Security-Token", valid_595296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595297 = header.getOrDefault("X-Amz-Target")
  valid_595297 = validateParameter(valid_595297, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_595297 != nil:
    section.add "X-Amz-Target", valid_595297
  var valid_595298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595298 = validateParameter(valid_595298, JString, required = false,
                                 default = nil)
  if valid_595298 != nil:
    section.add "X-Amz-Content-Sha256", valid_595298
  var valid_595299 = header.getOrDefault("X-Amz-Algorithm")
  valid_595299 = validateParameter(valid_595299, JString, required = false,
                                 default = nil)
  if valid_595299 != nil:
    section.add "X-Amz-Algorithm", valid_595299
  var valid_595300 = header.getOrDefault("X-Amz-Signature")
  valid_595300 = validateParameter(valid_595300, JString, required = false,
                                 default = nil)
  if valid_595300 != nil:
    section.add "X-Amz-Signature", valid_595300
  var valid_595301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595301 = validateParameter(valid_595301, JString, required = false,
                                 default = nil)
  if valid_595301 != nil:
    section.add "X-Amz-SignedHeaders", valid_595301
  var valid_595302 = header.getOrDefault("X-Amz-Credential")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = nil)
  if valid_595302 != nil:
    section.add "X-Amz-Credential", valid_595302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595304: Call_GetWorkflow_595292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_595304.validator(path, query, header, formData, body)
  let scheme = call_595304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595304.url(scheme.get, call_595304.host, call_595304.base,
                         call_595304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595304, url, valid)

proc call*(call_595305: Call_GetWorkflow_595292; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_595306 = newJObject()
  if body != nil:
    body_595306 = body
  result = call_595305.call(nil, nil, nil, nil, body_595306)

var getWorkflow* = Call_GetWorkflow_595292(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_595293,
                                        base: "/", url: url_GetWorkflow_595294,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_595307 = ref object of OpenApiRestCall_593437
proc url_GetWorkflowRun_595309(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRun_595308(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given workflow run. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595310 = header.getOrDefault("X-Amz-Date")
  valid_595310 = validateParameter(valid_595310, JString, required = false,
                                 default = nil)
  if valid_595310 != nil:
    section.add "X-Amz-Date", valid_595310
  var valid_595311 = header.getOrDefault("X-Amz-Security-Token")
  valid_595311 = validateParameter(valid_595311, JString, required = false,
                                 default = nil)
  if valid_595311 != nil:
    section.add "X-Amz-Security-Token", valid_595311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595312 = header.getOrDefault("X-Amz-Target")
  valid_595312 = validateParameter(valid_595312, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_595312 != nil:
    section.add "X-Amz-Target", valid_595312
  var valid_595313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595313 = validateParameter(valid_595313, JString, required = false,
                                 default = nil)
  if valid_595313 != nil:
    section.add "X-Amz-Content-Sha256", valid_595313
  var valid_595314 = header.getOrDefault("X-Amz-Algorithm")
  valid_595314 = validateParameter(valid_595314, JString, required = false,
                                 default = nil)
  if valid_595314 != nil:
    section.add "X-Amz-Algorithm", valid_595314
  var valid_595315 = header.getOrDefault("X-Amz-Signature")
  valid_595315 = validateParameter(valid_595315, JString, required = false,
                                 default = nil)
  if valid_595315 != nil:
    section.add "X-Amz-Signature", valid_595315
  var valid_595316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595316 = validateParameter(valid_595316, JString, required = false,
                                 default = nil)
  if valid_595316 != nil:
    section.add "X-Amz-SignedHeaders", valid_595316
  var valid_595317 = header.getOrDefault("X-Amz-Credential")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Credential", valid_595317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595319: Call_GetWorkflowRun_595307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_595319.validator(path, query, header, formData, body)
  let scheme = call_595319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595319.url(scheme.get, call_595319.host, call_595319.base,
                         call_595319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595319, url, valid)

proc call*(call_595320: Call_GetWorkflowRun_595307; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_595321 = newJObject()
  if body != nil:
    body_595321 = body
  result = call_595320.call(nil, nil, nil, nil, body_595321)

var getWorkflowRun* = Call_GetWorkflowRun_595307(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_595308, base: "/", url: url_GetWorkflowRun_595309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_595322 = ref object of OpenApiRestCall_593437
proc url_GetWorkflowRunProperties_595324(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRunProperties_595323(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the workflow run properties which were set during the run.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595325 = header.getOrDefault("X-Amz-Date")
  valid_595325 = validateParameter(valid_595325, JString, required = false,
                                 default = nil)
  if valid_595325 != nil:
    section.add "X-Amz-Date", valid_595325
  var valid_595326 = header.getOrDefault("X-Amz-Security-Token")
  valid_595326 = validateParameter(valid_595326, JString, required = false,
                                 default = nil)
  if valid_595326 != nil:
    section.add "X-Amz-Security-Token", valid_595326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595327 = header.getOrDefault("X-Amz-Target")
  valid_595327 = validateParameter(valid_595327, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_595327 != nil:
    section.add "X-Amz-Target", valid_595327
  var valid_595328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595328 = validateParameter(valid_595328, JString, required = false,
                                 default = nil)
  if valid_595328 != nil:
    section.add "X-Amz-Content-Sha256", valid_595328
  var valid_595329 = header.getOrDefault("X-Amz-Algorithm")
  valid_595329 = validateParameter(valid_595329, JString, required = false,
                                 default = nil)
  if valid_595329 != nil:
    section.add "X-Amz-Algorithm", valid_595329
  var valid_595330 = header.getOrDefault("X-Amz-Signature")
  valid_595330 = validateParameter(valid_595330, JString, required = false,
                                 default = nil)
  if valid_595330 != nil:
    section.add "X-Amz-Signature", valid_595330
  var valid_595331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595331 = validateParameter(valid_595331, JString, required = false,
                                 default = nil)
  if valid_595331 != nil:
    section.add "X-Amz-SignedHeaders", valid_595331
  var valid_595332 = header.getOrDefault("X-Amz-Credential")
  valid_595332 = validateParameter(valid_595332, JString, required = false,
                                 default = nil)
  if valid_595332 != nil:
    section.add "X-Amz-Credential", valid_595332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595334: Call_GetWorkflowRunProperties_595322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_595334.validator(path, query, header, formData, body)
  let scheme = call_595334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595334.url(scheme.get, call_595334.host, call_595334.base,
                         call_595334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595334, url, valid)

proc call*(call_595335: Call_GetWorkflowRunProperties_595322; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_595336 = newJObject()
  if body != nil:
    body_595336 = body
  result = call_595335.call(nil, nil, nil, nil, body_595336)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_595322(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_595323, base: "/",
    url: url_GetWorkflowRunProperties_595324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_595337 = ref object of OpenApiRestCall_593437
proc url_GetWorkflowRuns_595339(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRuns_595338(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595340 = query.getOrDefault("NextToken")
  valid_595340 = validateParameter(valid_595340, JString, required = false,
                                 default = nil)
  if valid_595340 != nil:
    section.add "NextToken", valid_595340
  var valid_595341 = query.getOrDefault("MaxResults")
  valid_595341 = validateParameter(valid_595341, JString, required = false,
                                 default = nil)
  if valid_595341 != nil:
    section.add "MaxResults", valid_595341
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595342 = header.getOrDefault("X-Amz-Date")
  valid_595342 = validateParameter(valid_595342, JString, required = false,
                                 default = nil)
  if valid_595342 != nil:
    section.add "X-Amz-Date", valid_595342
  var valid_595343 = header.getOrDefault("X-Amz-Security-Token")
  valid_595343 = validateParameter(valid_595343, JString, required = false,
                                 default = nil)
  if valid_595343 != nil:
    section.add "X-Amz-Security-Token", valid_595343
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595344 = header.getOrDefault("X-Amz-Target")
  valid_595344 = validateParameter(valid_595344, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_595344 != nil:
    section.add "X-Amz-Target", valid_595344
  var valid_595345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595345 = validateParameter(valid_595345, JString, required = false,
                                 default = nil)
  if valid_595345 != nil:
    section.add "X-Amz-Content-Sha256", valid_595345
  var valid_595346 = header.getOrDefault("X-Amz-Algorithm")
  valid_595346 = validateParameter(valid_595346, JString, required = false,
                                 default = nil)
  if valid_595346 != nil:
    section.add "X-Amz-Algorithm", valid_595346
  var valid_595347 = header.getOrDefault("X-Amz-Signature")
  valid_595347 = validateParameter(valid_595347, JString, required = false,
                                 default = nil)
  if valid_595347 != nil:
    section.add "X-Amz-Signature", valid_595347
  var valid_595348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595348 = validateParameter(valid_595348, JString, required = false,
                                 default = nil)
  if valid_595348 != nil:
    section.add "X-Amz-SignedHeaders", valid_595348
  var valid_595349 = header.getOrDefault("X-Amz-Credential")
  valid_595349 = validateParameter(valid_595349, JString, required = false,
                                 default = nil)
  if valid_595349 != nil:
    section.add "X-Amz-Credential", valid_595349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595351: Call_GetWorkflowRuns_595337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_595351.validator(path, query, header, formData, body)
  let scheme = call_595351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595351.url(scheme.get, call_595351.host, call_595351.base,
                         call_595351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595351, url, valid)

proc call*(call_595352: Call_GetWorkflowRuns_595337; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595353 = newJObject()
  var body_595354 = newJObject()
  add(query_595353, "NextToken", newJString(NextToken))
  if body != nil:
    body_595354 = body
  add(query_595353, "MaxResults", newJString(MaxResults))
  result = call_595352.call(nil, query_595353, nil, nil, body_595354)

var getWorkflowRuns* = Call_GetWorkflowRuns_595337(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_595338, base: "/", url: url_GetWorkflowRuns_595339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_595355 = ref object of OpenApiRestCall_593437
proc url_ImportCatalogToGlue_595357(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportCatalogToGlue_595356(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595358 = header.getOrDefault("X-Amz-Date")
  valid_595358 = validateParameter(valid_595358, JString, required = false,
                                 default = nil)
  if valid_595358 != nil:
    section.add "X-Amz-Date", valid_595358
  var valid_595359 = header.getOrDefault("X-Amz-Security-Token")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "X-Amz-Security-Token", valid_595359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595360 = header.getOrDefault("X-Amz-Target")
  valid_595360 = validateParameter(valid_595360, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_595360 != nil:
    section.add "X-Amz-Target", valid_595360
  var valid_595361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595361 = validateParameter(valid_595361, JString, required = false,
                                 default = nil)
  if valid_595361 != nil:
    section.add "X-Amz-Content-Sha256", valid_595361
  var valid_595362 = header.getOrDefault("X-Amz-Algorithm")
  valid_595362 = validateParameter(valid_595362, JString, required = false,
                                 default = nil)
  if valid_595362 != nil:
    section.add "X-Amz-Algorithm", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-Signature")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-Signature", valid_595363
  var valid_595364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595364 = validateParameter(valid_595364, JString, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "X-Amz-SignedHeaders", valid_595364
  var valid_595365 = header.getOrDefault("X-Amz-Credential")
  valid_595365 = validateParameter(valid_595365, JString, required = false,
                                 default = nil)
  if valid_595365 != nil:
    section.add "X-Amz-Credential", valid_595365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595367: Call_ImportCatalogToGlue_595355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_595367.validator(path, query, header, formData, body)
  let scheme = call_595367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595367.url(scheme.get, call_595367.host, call_595367.base,
                         call_595367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595367, url, valid)

proc call*(call_595368: Call_ImportCatalogToGlue_595355; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_595369 = newJObject()
  if body != nil:
    body_595369 = body
  result = call_595368.call(nil, nil, nil, nil, body_595369)

var importCatalogToGlue* = Call_ImportCatalogToGlue_595355(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_595356, base: "/",
    url: url_ImportCatalogToGlue_595357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_595370 = ref object of OpenApiRestCall_593437
proc url_ListCrawlers_595372(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCrawlers_595371(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595373 = query.getOrDefault("NextToken")
  valid_595373 = validateParameter(valid_595373, JString, required = false,
                                 default = nil)
  if valid_595373 != nil:
    section.add "NextToken", valid_595373
  var valid_595374 = query.getOrDefault("MaxResults")
  valid_595374 = validateParameter(valid_595374, JString, required = false,
                                 default = nil)
  if valid_595374 != nil:
    section.add "MaxResults", valid_595374
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595375 = header.getOrDefault("X-Amz-Date")
  valid_595375 = validateParameter(valid_595375, JString, required = false,
                                 default = nil)
  if valid_595375 != nil:
    section.add "X-Amz-Date", valid_595375
  var valid_595376 = header.getOrDefault("X-Amz-Security-Token")
  valid_595376 = validateParameter(valid_595376, JString, required = false,
                                 default = nil)
  if valid_595376 != nil:
    section.add "X-Amz-Security-Token", valid_595376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595377 = header.getOrDefault("X-Amz-Target")
  valid_595377 = validateParameter(valid_595377, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_595377 != nil:
    section.add "X-Amz-Target", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-Content-Sha256", valid_595378
  var valid_595379 = header.getOrDefault("X-Amz-Algorithm")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "X-Amz-Algorithm", valid_595379
  var valid_595380 = header.getOrDefault("X-Amz-Signature")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "X-Amz-Signature", valid_595380
  var valid_595381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595381 = validateParameter(valid_595381, JString, required = false,
                                 default = nil)
  if valid_595381 != nil:
    section.add "X-Amz-SignedHeaders", valid_595381
  var valid_595382 = header.getOrDefault("X-Amz-Credential")
  valid_595382 = validateParameter(valid_595382, JString, required = false,
                                 default = nil)
  if valid_595382 != nil:
    section.add "X-Amz-Credential", valid_595382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595384: Call_ListCrawlers_595370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_595384.validator(path, query, header, formData, body)
  let scheme = call_595384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595384.url(scheme.get, call_595384.host, call_595384.base,
                         call_595384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595384, url, valid)

proc call*(call_595385: Call_ListCrawlers_595370; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595386 = newJObject()
  var body_595387 = newJObject()
  add(query_595386, "NextToken", newJString(NextToken))
  if body != nil:
    body_595387 = body
  add(query_595386, "MaxResults", newJString(MaxResults))
  result = call_595385.call(nil, query_595386, nil, nil, body_595387)

var listCrawlers* = Call_ListCrawlers_595370(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_595371, base: "/", url: url_ListCrawlers_595372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_595388 = ref object of OpenApiRestCall_593437
proc url_ListDevEndpoints_595390(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevEndpoints_595389(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595391 = query.getOrDefault("NextToken")
  valid_595391 = validateParameter(valid_595391, JString, required = false,
                                 default = nil)
  if valid_595391 != nil:
    section.add "NextToken", valid_595391
  var valid_595392 = query.getOrDefault("MaxResults")
  valid_595392 = validateParameter(valid_595392, JString, required = false,
                                 default = nil)
  if valid_595392 != nil:
    section.add "MaxResults", valid_595392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595393 = header.getOrDefault("X-Amz-Date")
  valid_595393 = validateParameter(valid_595393, JString, required = false,
                                 default = nil)
  if valid_595393 != nil:
    section.add "X-Amz-Date", valid_595393
  var valid_595394 = header.getOrDefault("X-Amz-Security-Token")
  valid_595394 = validateParameter(valid_595394, JString, required = false,
                                 default = nil)
  if valid_595394 != nil:
    section.add "X-Amz-Security-Token", valid_595394
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595395 = header.getOrDefault("X-Amz-Target")
  valid_595395 = validateParameter(valid_595395, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_595395 != nil:
    section.add "X-Amz-Target", valid_595395
  var valid_595396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595396 = validateParameter(valid_595396, JString, required = false,
                                 default = nil)
  if valid_595396 != nil:
    section.add "X-Amz-Content-Sha256", valid_595396
  var valid_595397 = header.getOrDefault("X-Amz-Algorithm")
  valid_595397 = validateParameter(valid_595397, JString, required = false,
                                 default = nil)
  if valid_595397 != nil:
    section.add "X-Amz-Algorithm", valid_595397
  var valid_595398 = header.getOrDefault("X-Amz-Signature")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "X-Amz-Signature", valid_595398
  var valid_595399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "X-Amz-SignedHeaders", valid_595399
  var valid_595400 = header.getOrDefault("X-Amz-Credential")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "X-Amz-Credential", valid_595400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595402: Call_ListDevEndpoints_595388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_595402.validator(path, query, header, formData, body)
  let scheme = call_595402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595402.url(scheme.get, call_595402.host, call_595402.base,
                         call_595402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595402, url, valid)

proc call*(call_595403: Call_ListDevEndpoints_595388; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595404 = newJObject()
  var body_595405 = newJObject()
  add(query_595404, "NextToken", newJString(NextToken))
  if body != nil:
    body_595405 = body
  add(query_595404, "MaxResults", newJString(MaxResults))
  result = call_595403.call(nil, query_595404, nil, nil, body_595405)

var listDevEndpoints* = Call_ListDevEndpoints_595388(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_595389, base: "/",
    url: url_ListDevEndpoints_595390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_595406 = ref object of OpenApiRestCall_593437
proc url_ListJobs_595408(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_595407(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595409 = query.getOrDefault("NextToken")
  valid_595409 = validateParameter(valid_595409, JString, required = false,
                                 default = nil)
  if valid_595409 != nil:
    section.add "NextToken", valid_595409
  var valid_595410 = query.getOrDefault("MaxResults")
  valid_595410 = validateParameter(valid_595410, JString, required = false,
                                 default = nil)
  if valid_595410 != nil:
    section.add "MaxResults", valid_595410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595411 = header.getOrDefault("X-Amz-Date")
  valid_595411 = validateParameter(valid_595411, JString, required = false,
                                 default = nil)
  if valid_595411 != nil:
    section.add "X-Amz-Date", valid_595411
  var valid_595412 = header.getOrDefault("X-Amz-Security-Token")
  valid_595412 = validateParameter(valid_595412, JString, required = false,
                                 default = nil)
  if valid_595412 != nil:
    section.add "X-Amz-Security-Token", valid_595412
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595413 = header.getOrDefault("X-Amz-Target")
  valid_595413 = validateParameter(valid_595413, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_595413 != nil:
    section.add "X-Amz-Target", valid_595413
  var valid_595414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595414 = validateParameter(valid_595414, JString, required = false,
                                 default = nil)
  if valid_595414 != nil:
    section.add "X-Amz-Content-Sha256", valid_595414
  var valid_595415 = header.getOrDefault("X-Amz-Algorithm")
  valid_595415 = validateParameter(valid_595415, JString, required = false,
                                 default = nil)
  if valid_595415 != nil:
    section.add "X-Amz-Algorithm", valid_595415
  var valid_595416 = header.getOrDefault("X-Amz-Signature")
  valid_595416 = validateParameter(valid_595416, JString, required = false,
                                 default = nil)
  if valid_595416 != nil:
    section.add "X-Amz-Signature", valid_595416
  var valid_595417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595417 = validateParameter(valid_595417, JString, required = false,
                                 default = nil)
  if valid_595417 != nil:
    section.add "X-Amz-SignedHeaders", valid_595417
  var valid_595418 = header.getOrDefault("X-Amz-Credential")
  valid_595418 = validateParameter(valid_595418, JString, required = false,
                                 default = nil)
  if valid_595418 != nil:
    section.add "X-Amz-Credential", valid_595418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595420: Call_ListJobs_595406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_595420.validator(path, query, header, formData, body)
  let scheme = call_595420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595420.url(scheme.get, call_595420.host, call_595420.base,
                         call_595420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595420, url, valid)

proc call*(call_595421: Call_ListJobs_595406; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595422 = newJObject()
  var body_595423 = newJObject()
  add(query_595422, "NextToken", newJString(NextToken))
  if body != nil:
    body_595423 = body
  add(query_595422, "MaxResults", newJString(MaxResults))
  result = call_595421.call(nil, query_595422, nil, nil, body_595423)

var listJobs* = Call_ListJobs_595406(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_595407, base: "/",
                                  url: url_ListJobs_595408,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_595424 = ref object of OpenApiRestCall_593437
proc url_ListTriggers_595426(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTriggers_595425(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595427 = query.getOrDefault("NextToken")
  valid_595427 = validateParameter(valid_595427, JString, required = false,
                                 default = nil)
  if valid_595427 != nil:
    section.add "NextToken", valid_595427
  var valid_595428 = query.getOrDefault("MaxResults")
  valid_595428 = validateParameter(valid_595428, JString, required = false,
                                 default = nil)
  if valid_595428 != nil:
    section.add "MaxResults", valid_595428
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595429 = header.getOrDefault("X-Amz-Date")
  valid_595429 = validateParameter(valid_595429, JString, required = false,
                                 default = nil)
  if valid_595429 != nil:
    section.add "X-Amz-Date", valid_595429
  var valid_595430 = header.getOrDefault("X-Amz-Security-Token")
  valid_595430 = validateParameter(valid_595430, JString, required = false,
                                 default = nil)
  if valid_595430 != nil:
    section.add "X-Amz-Security-Token", valid_595430
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595431 = header.getOrDefault("X-Amz-Target")
  valid_595431 = validateParameter(valid_595431, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_595431 != nil:
    section.add "X-Amz-Target", valid_595431
  var valid_595432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595432 = validateParameter(valid_595432, JString, required = false,
                                 default = nil)
  if valid_595432 != nil:
    section.add "X-Amz-Content-Sha256", valid_595432
  var valid_595433 = header.getOrDefault("X-Amz-Algorithm")
  valid_595433 = validateParameter(valid_595433, JString, required = false,
                                 default = nil)
  if valid_595433 != nil:
    section.add "X-Amz-Algorithm", valid_595433
  var valid_595434 = header.getOrDefault("X-Amz-Signature")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "X-Amz-Signature", valid_595434
  var valid_595435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595435 = validateParameter(valid_595435, JString, required = false,
                                 default = nil)
  if valid_595435 != nil:
    section.add "X-Amz-SignedHeaders", valid_595435
  var valid_595436 = header.getOrDefault("X-Amz-Credential")
  valid_595436 = validateParameter(valid_595436, JString, required = false,
                                 default = nil)
  if valid_595436 != nil:
    section.add "X-Amz-Credential", valid_595436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595438: Call_ListTriggers_595424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_595438.validator(path, query, header, formData, body)
  let scheme = call_595438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595438.url(scheme.get, call_595438.host, call_595438.base,
                         call_595438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595438, url, valid)

proc call*(call_595439: Call_ListTriggers_595424; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595440 = newJObject()
  var body_595441 = newJObject()
  add(query_595440, "NextToken", newJString(NextToken))
  if body != nil:
    body_595441 = body
  add(query_595440, "MaxResults", newJString(MaxResults))
  result = call_595439.call(nil, query_595440, nil, nil, body_595441)

var listTriggers* = Call_ListTriggers_595424(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_595425, base: "/", url: url_ListTriggers_595426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_595442 = ref object of OpenApiRestCall_593437
proc url_ListWorkflows_595444(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkflows_595443(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists names of workflows created in the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595445 = query.getOrDefault("NextToken")
  valid_595445 = validateParameter(valid_595445, JString, required = false,
                                 default = nil)
  if valid_595445 != nil:
    section.add "NextToken", valid_595445
  var valid_595446 = query.getOrDefault("MaxResults")
  valid_595446 = validateParameter(valid_595446, JString, required = false,
                                 default = nil)
  if valid_595446 != nil:
    section.add "MaxResults", valid_595446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595447 = header.getOrDefault("X-Amz-Date")
  valid_595447 = validateParameter(valid_595447, JString, required = false,
                                 default = nil)
  if valid_595447 != nil:
    section.add "X-Amz-Date", valid_595447
  var valid_595448 = header.getOrDefault("X-Amz-Security-Token")
  valid_595448 = validateParameter(valid_595448, JString, required = false,
                                 default = nil)
  if valid_595448 != nil:
    section.add "X-Amz-Security-Token", valid_595448
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595449 = header.getOrDefault("X-Amz-Target")
  valid_595449 = validateParameter(valid_595449, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_595449 != nil:
    section.add "X-Amz-Target", valid_595449
  var valid_595450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595450 = validateParameter(valid_595450, JString, required = false,
                                 default = nil)
  if valid_595450 != nil:
    section.add "X-Amz-Content-Sha256", valid_595450
  var valid_595451 = header.getOrDefault("X-Amz-Algorithm")
  valid_595451 = validateParameter(valid_595451, JString, required = false,
                                 default = nil)
  if valid_595451 != nil:
    section.add "X-Amz-Algorithm", valid_595451
  var valid_595452 = header.getOrDefault("X-Amz-Signature")
  valid_595452 = validateParameter(valid_595452, JString, required = false,
                                 default = nil)
  if valid_595452 != nil:
    section.add "X-Amz-Signature", valid_595452
  var valid_595453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "X-Amz-SignedHeaders", valid_595453
  var valid_595454 = header.getOrDefault("X-Amz-Credential")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-Credential", valid_595454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595456: Call_ListWorkflows_595442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_595456.validator(path, query, header, formData, body)
  let scheme = call_595456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595456.url(scheme.get, call_595456.host, call_595456.base,
                         call_595456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595456, url, valid)

proc call*(call_595457: Call_ListWorkflows_595442; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595458 = newJObject()
  var body_595459 = newJObject()
  add(query_595458, "NextToken", newJString(NextToken))
  if body != nil:
    body_595459 = body
  add(query_595458, "MaxResults", newJString(MaxResults))
  result = call_595457.call(nil, query_595458, nil, nil, body_595459)

var listWorkflows* = Call_ListWorkflows_595442(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_595443, base: "/", url: url_ListWorkflows_595444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_595460 = ref object of OpenApiRestCall_593437
proc url_PutDataCatalogEncryptionSettings_595462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_595461(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595463 = header.getOrDefault("X-Amz-Date")
  valid_595463 = validateParameter(valid_595463, JString, required = false,
                                 default = nil)
  if valid_595463 != nil:
    section.add "X-Amz-Date", valid_595463
  var valid_595464 = header.getOrDefault("X-Amz-Security-Token")
  valid_595464 = validateParameter(valid_595464, JString, required = false,
                                 default = nil)
  if valid_595464 != nil:
    section.add "X-Amz-Security-Token", valid_595464
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595465 = header.getOrDefault("X-Amz-Target")
  valid_595465 = validateParameter(valid_595465, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_595465 != nil:
    section.add "X-Amz-Target", valid_595465
  var valid_595466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595466 = validateParameter(valid_595466, JString, required = false,
                                 default = nil)
  if valid_595466 != nil:
    section.add "X-Amz-Content-Sha256", valid_595466
  var valid_595467 = header.getOrDefault("X-Amz-Algorithm")
  valid_595467 = validateParameter(valid_595467, JString, required = false,
                                 default = nil)
  if valid_595467 != nil:
    section.add "X-Amz-Algorithm", valid_595467
  var valid_595468 = header.getOrDefault("X-Amz-Signature")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "X-Amz-Signature", valid_595468
  var valid_595469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-SignedHeaders", valid_595469
  var valid_595470 = header.getOrDefault("X-Amz-Credential")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "X-Amz-Credential", valid_595470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595472: Call_PutDataCatalogEncryptionSettings_595460;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_595472.validator(path, query, header, formData, body)
  let scheme = call_595472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595472.url(scheme.get, call_595472.host, call_595472.base,
                         call_595472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595472, url, valid)

proc call*(call_595473: Call_PutDataCatalogEncryptionSettings_595460;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_595474 = newJObject()
  if body != nil:
    body_595474 = body
  result = call_595473.call(nil, nil, nil, nil, body_595474)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_595460(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_595461, base: "/",
    url: url_PutDataCatalogEncryptionSettings_595462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_595475 = ref object of OpenApiRestCall_593437
proc url_PutResourcePolicy_595477(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutResourcePolicy_595476(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Sets the Data Catalog resource policy for access control.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595478 = header.getOrDefault("X-Amz-Date")
  valid_595478 = validateParameter(valid_595478, JString, required = false,
                                 default = nil)
  if valid_595478 != nil:
    section.add "X-Amz-Date", valid_595478
  var valid_595479 = header.getOrDefault("X-Amz-Security-Token")
  valid_595479 = validateParameter(valid_595479, JString, required = false,
                                 default = nil)
  if valid_595479 != nil:
    section.add "X-Amz-Security-Token", valid_595479
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595480 = header.getOrDefault("X-Amz-Target")
  valid_595480 = validateParameter(valid_595480, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_595480 != nil:
    section.add "X-Amz-Target", valid_595480
  var valid_595481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595481 = validateParameter(valid_595481, JString, required = false,
                                 default = nil)
  if valid_595481 != nil:
    section.add "X-Amz-Content-Sha256", valid_595481
  var valid_595482 = header.getOrDefault("X-Amz-Algorithm")
  valid_595482 = validateParameter(valid_595482, JString, required = false,
                                 default = nil)
  if valid_595482 != nil:
    section.add "X-Amz-Algorithm", valid_595482
  var valid_595483 = header.getOrDefault("X-Amz-Signature")
  valid_595483 = validateParameter(valid_595483, JString, required = false,
                                 default = nil)
  if valid_595483 != nil:
    section.add "X-Amz-Signature", valid_595483
  var valid_595484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "X-Amz-SignedHeaders", valid_595484
  var valid_595485 = header.getOrDefault("X-Amz-Credential")
  valid_595485 = validateParameter(valid_595485, JString, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "X-Amz-Credential", valid_595485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595487: Call_PutResourcePolicy_595475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_595487.validator(path, query, header, formData, body)
  let scheme = call_595487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595487.url(scheme.get, call_595487.host, call_595487.base,
                         call_595487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595487, url, valid)

proc call*(call_595488: Call_PutResourcePolicy_595475; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_595489 = newJObject()
  if body != nil:
    body_595489 = body
  result = call_595488.call(nil, nil, nil, nil, body_595489)

var putResourcePolicy* = Call_PutResourcePolicy_595475(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_595476, base: "/",
    url: url_PutResourcePolicy_595477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_595490 = ref object of OpenApiRestCall_593437
proc url_PutWorkflowRunProperties_595492(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutWorkflowRunProperties_595491(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595493 = header.getOrDefault("X-Amz-Date")
  valid_595493 = validateParameter(valid_595493, JString, required = false,
                                 default = nil)
  if valid_595493 != nil:
    section.add "X-Amz-Date", valid_595493
  var valid_595494 = header.getOrDefault("X-Amz-Security-Token")
  valid_595494 = validateParameter(valid_595494, JString, required = false,
                                 default = nil)
  if valid_595494 != nil:
    section.add "X-Amz-Security-Token", valid_595494
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595495 = header.getOrDefault("X-Amz-Target")
  valid_595495 = validateParameter(valid_595495, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_595495 != nil:
    section.add "X-Amz-Target", valid_595495
  var valid_595496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595496 = validateParameter(valid_595496, JString, required = false,
                                 default = nil)
  if valid_595496 != nil:
    section.add "X-Amz-Content-Sha256", valid_595496
  var valid_595497 = header.getOrDefault("X-Amz-Algorithm")
  valid_595497 = validateParameter(valid_595497, JString, required = false,
                                 default = nil)
  if valid_595497 != nil:
    section.add "X-Amz-Algorithm", valid_595497
  var valid_595498 = header.getOrDefault("X-Amz-Signature")
  valid_595498 = validateParameter(valid_595498, JString, required = false,
                                 default = nil)
  if valid_595498 != nil:
    section.add "X-Amz-Signature", valid_595498
  var valid_595499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "X-Amz-SignedHeaders", valid_595499
  var valid_595500 = header.getOrDefault("X-Amz-Credential")
  valid_595500 = validateParameter(valid_595500, JString, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "X-Amz-Credential", valid_595500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595502: Call_PutWorkflowRunProperties_595490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_595502.validator(path, query, header, formData, body)
  let scheme = call_595502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595502.url(scheme.get, call_595502.host, call_595502.base,
                         call_595502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595502, url, valid)

proc call*(call_595503: Call_PutWorkflowRunProperties_595490; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_595504 = newJObject()
  if body != nil:
    body_595504 = body
  result = call_595503.call(nil, nil, nil, nil, body_595504)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_595490(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_595491, base: "/",
    url: url_PutWorkflowRunProperties_595492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_595505 = ref object of OpenApiRestCall_593437
proc url_ResetJobBookmark_595507(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetJobBookmark_595506(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets a bookmark entry.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595508 = header.getOrDefault("X-Amz-Date")
  valid_595508 = validateParameter(valid_595508, JString, required = false,
                                 default = nil)
  if valid_595508 != nil:
    section.add "X-Amz-Date", valid_595508
  var valid_595509 = header.getOrDefault("X-Amz-Security-Token")
  valid_595509 = validateParameter(valid_595509, JString, required = false,
                                 default = nil)
  if valid_595509 != nil:
    section.add "X-Amz-Security-Token", valid_595509
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595510 = header.getOrDefault("X-Amz-Target")
  valid_595510 = validateParameter(valid_595510, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_595510 != nil:
    section.add "X-Amz-Target", valid_595510
  var valid_595511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595511 = validateParameter(valid_595511, JString, required = false,
                                 default = nil)
  if valid_595511 != nil:
    section.add "X-Amz-Content-Sha256", valid_595511
  var valid_595512 = header.getOrDefault("X-Amz-Algorithm")
  valid_595512 = validateParameter(valid_595512, JString, required = false,
                                 default = nil)
  if valid_595512 != nil:
    section.add "X-Amz-Algorithm", valid_595512
  var valid_595513 = header.getOrDefault("X-Amz-Signature")
  valid_595513 = validateParameter(valid_595513, JString, required = false,
                                 default = nil)
  if valid_595513 != nil:
    section.add "X-Amz-Signature", valid_595513
  var valid_595514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "X-Amz-SignedHeaders", valid_595514
  var valid_595515 = header.getOrDefault("X-Amz-Credential")
  valid_595515 = validateParameter(valid_595515, JString, required = false,
                                 default = nil)
  if valid_595515 != nil:
    section.add "X-Amz-Credential", valid_595515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595517: Call_ResetJobBookmark_595505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_595517.validator(path, query, header, formData, body)
  let scheme = call_595517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595517.url(scheme.get, call_595517.host, call_595517.base,
                         call_595517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595517, url, valid)

proc call*(call_595518: Call_ResetJobBookmark_595505; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_595519 = newJObject()
  if body != nil:
    body_595519 = body
  result = call_595518.call(nil, nil, nil, nil, body_595519)

var resetJobBookmark* = Call_ResetJobBookmark_595505(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_595506, base: "/",
    url: url_ResetJobBookmark_595507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_595520 = ref object of OpenApiRestCall_593437
proc url_SearchTables_595522(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchTables_595521(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_595523 = query.getOrDefault("NextToken")
  valid_595523 = validateParameter(valid_595523, JString, required = false,
                                 default = nil)
  if valid_595523 != nil:
    section.add "NextToken", valid_595523
  var valid_595524 = query.getOrDefault("MaxResults")
  valid_595524 = validateParameter(valid_595524, JString, required = false,
                                 default = nil)
  if valid_595524 != nil:
    section.add "MaxResults", valid_595524
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595525 = header.getOrDefault("X-Amz-Date")
  valid_595525 = validateParameter(valid_595525, JString, required = false,
                                 default = nil)
  if valid_595525 != nil:
    section.add "X-Amz-Date", valid_595525
  var valid_595526 = header.getOrDefault("X-Amz-Security-Token")
  valid_595526 = validateParameter(valid_595526, JString, required = false,
                                 default = nil)
  if valid_595526 != nil:
    section.add "X-Amz-Security-Token", valid_595526
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595527 = header.getOrDefault("X-Amz-Target")
  valid_595527 = validateParameter(valid_595527, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_595527 != nil:
    section.add "X-Amz-Target", valid_595527
  var valid_595528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595528 = validateParameter(valid_595528, JString, required = false,
                                 default = nil)
  if valid_595528 != nil:
    section.add "X-Amz-Content-Sha256", valid_595528
  var valid_595529 = header.getOrDefault("X-Amz-Algorithm")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "X-Amz-Algorithm", valid_595529
  var valid_595530 = header.getOrDefault("X-Amz-Signature")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "X-Amz-Signature", valid_595530
  var valid_595531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595531 = validateParameter(valid_595531, JString, required = false,
                                 default = nil)
  if valid_595531 != nil:
    section.add "X-Amz-SignedHeaders", valid_595531
  var valid_595532 = header.getOrDefault("X-Amz-Credential")
  valid_595532 = validateParameter(valid_595532, JString, required = false,
                                 default = nil)
  if valid_595532 != nil:
    section.add "X-Amz-Credential", valid_595532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595534: Call_SearchTables_595520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_595534.validator(path, query, header, formData, body)
  let scheme = call_595534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595534.url(scheme.get, call_595534.host, call_595534.base,
                         call_595534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595534, url, valid)

proc call*(call_595535: Call_SearchTables_595520; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595536 = newJObject()
  var body_595537 = newJObject()
  add(query_595536, "NextToken", newJString(NextToken))
  if body != nil:
    body_595537 = body
  add(query_595536, "MaxResults", newJString(MaxResults))
  result = call_595535.call(nil, query_595536, nil, nil, body_595537)

var searchTables* = Call_SearchTables_595520(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_595521, base: "/", url: url_SearchTables_595522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_595538 = ref object of OpenApiRestCall_593437
proc url_StartCrawler_595540(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawler_595539(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595541 = header.getOrDefault("X-Amz-Date")
  valid_595541 = validateParameter(valid_595541, JString, required = false,
                                 default = nil)
  if valid_595541 != nil:
    section.add "X-Amz-Date", valid_595541
  var valid_595542 = header.getOrDefault("X-Amz-Security-Token")
  valid_595542 = validateParameter(valid_595542, JString, required = false,
                                 default = nil)
  if valid_595542 != nil:
    section.add "X-Amz-Security-Token", valid_595542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595543 = header.getOrDefault("X-Amz-Target")
  valid_595543 = validateParameter(valid_595543, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_595543 != nil:
    section.add "X-Amz-Target", valid_595543
  var valid_595544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-Content-Sha256", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Algorithm")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Algorithm", valid_595545
  var valid_595546 = header.getOrDefault("X-Amz-Signature")
  valid_595546 = validateParameter(valid_595546, JString, required = false,
                                 default = nil)
  if valid_595546 != nil:
    section.add "X-Amz-Signature", valid_595546
  var valid_595547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595547 = validateParameter(valid_595547, JString, required = false,
                                 default = nil)
  if valid_595547 != nil:
    section.add "X-Amz-SignedHeaders", valid_595547
  var valid_595548 = header.getOrDefault("X-Amz-Credential")
  valid_595548 = validateParameter(valid_595548, JString, required = false,
                                 default = nil)
  if valid_595548 != nil:
    section.add "X-Amz-Credential", valid_595548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595550: Call_StartCrawler_595538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_595550.validator(path, query, header, formData, body)
  let scheme = call_595550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595550.url(scheme.get, call_595550.host, call_595550.base,
                         call_595550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595550, url, valid)

proc call*(call_595551: Call_StartCrawler_595538; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_595552 = newJObject()
  if body != nil:
    body_595552 = body
  result = call_595551.call(nil, nil, nil, nil, body_595552)

var startCrawler* = Call_StartCrawler_595538(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_595539, base: "/", url: url_StartCrawler_595540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_595553 = ref object of OpenApiRestCall_593437
proc url_StartCrawlerSchedule_595555(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawlerSchedule_595554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595556 = header.getOrDefault("X-Amz-Date")
  valid_595556 = validateParameter(valid_595556, JString, required = false,
                                 default = nil)
  if valid_595556 != nil:
    section.add "X-Amz-Date", valid_595556
  var valid_595557 = header.getOrDefault("X-Amz-Security-Token")
  valid_595557 = validateParameter(valid_595557, JString, required = false,
                                 default = nil)
  if valid_595557 != nil:
    section.add "X-Amz-Security-Token", valid_595557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595558 = header.getOrDefault("X-Amz-Target")
  valid_595558 = validateParameter(valid_595558, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_595558 != nil:
    section.add "X-Amz-Target", valid_595558
  var valid_595559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-Content-Sha256", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Algorithm")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Algorithm", valid_595560
  var valid_595561 = header.getOrDefault("X-Amz-Signature")
  valid_595561 = validateParameter(valid_595561, JString, required = false,
                                 default = nil)
  if valid_595561 != nil:
    section.add "X-Amz-Signature", valid_595561
  var valid_595562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595562 = validateParameter(valid_595562, JString, required = false,
                                 default = nil)
  if valid_595562 != nil:
    section.add "X-Amz-SignedHeaders", valid_595562
  var valid_595563 = header.getOrDefault("X-Amz-Credential")
  valid_595563 = validateParameter(valid_595563, JString, required = false,
                                 default = nil)
  if valid_595563 != nil:
    section.add "X-Amz-Credential", valid_595563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595565: Call_StartCrawlerSchedule_595553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_595565.validator(path, query, header, formData, body)
  let scheme = call_595565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595565.url(scheme.get, call_595565.host, call_595565.base,
                         call_595565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595565, url, valid)

proc call*(call_595566: Call_StartCrawlerSchedule_595553; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_595567 = newJObject()
  if body != nil:
    body_595567 = body
  result = call_595566.call(nil, nil, nil, nil, body_595567)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_595553(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_595554, base: "/",
    url: url_StartCrawlerSchedule_595555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_595568 = ref object of OpenApiRestCall_593437
proc url_StartExportLabelsTaskRun_595570(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartExportLabelsTaskRun_595569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595571 = header.getOrDefault("X-Amz-Date")
  valid_595571 = validateParameter(valid_595571, JString, required = false,
                                 default = nil)
  if valid_595571 != nil:
    section.add "X-Amz-Date", valid_595571
  var valid_595572 = header.getOrDefault("X-Amz-Security-Token")
  valid_595572 = validateParameter(valid_595572, JString, required = false,
                                 default = nil)
  if valid_595572 != nil:
    section.add "X-Amz-Security-Token", valid_595572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595573 = header.getOrDefault("X-Amz-Target")
  valid_595573 = validateParameter(valid_595573, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_595573 != nil:
    section.add "X-Amz-Target", valid_595573
  var valid_595574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595574 = validateParameter(valid_595574, JString, required = false,
                                 default = nil)
  if valid_595574 != nil:
    section.add "X-Amz-Content-Sha256", valid_595574
  var valid_595575 = header.getOrDefault("X-Amz-Algorithm")
  valid_595575 = validateParameter(valid_595575, JString, required = false,
                                 default = nil)
  if valid_595575 != nil:
    section.add "X-Amz-Algorithm", valid_595575
  var valid_595576 = header.getOrDefault("X-Amz-Signature")
  valid_595576 = validateParameter(valid_595576, JString, required = false,
                                 default = nil)
  if valid_595576 != nil:
    section.add "X-Amz-Signature", valid_595576
  var valid_595577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595577 = validateParameter(valid_595577, JString, required = false,
                                 default = nil)
  if valid_595577 != nil:
    section.add "X-Amz-SignedHeaders", valid_595577
  var valid_595578 = header.getOrDefault("X-Amz-Credential")
  valid_595578 = validateParameter(valid_595578, JString, required = false,
                                 default = nil)
  if valid_595578 != nil:
    section.add "X-Amz-Credential", valid_595578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595580: Call_StartExportLabelsTaskRun_595568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_595580.validator(path, query, header, formData, body)
  let scheme = call_595580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595580.url(scheme.get, call_595580.host, call_595580.base,
                         call_595580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595580, url, valid)

proc call*(call_595581: Call_StartExportLabelsTaskRun_595568; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_595582 = newJObject()
  if body != nil:
    body_595582 = body
  result = call_595581.call(nil, nil, nil, nil, body_595582)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_595568(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_595569, base: "/",
    url: url_StartExportLabelsTaskRun_595570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_595583 = ref object of OpenApiRestCall_593437
proc url_StartImportLabelsTaskRun_595585(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImportLabelsTaskRun_595584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595586 = header.getOrDefault("X-Amz-Date")
  valid_595586 = validateParameter(valid_595586, JString, required = false,
                                 default = nil)
  if valid_595586 != nil:
    section.add "X-Amz-Date", valid_595586
  var valid_595587 = header.getOrDefault("X-Amz-Security-Token")
  valid_595587 = validateParameter(valid_595587, JString, required = false,
                                 default = nil)
  if valid_595587 != nil:
    section.add "X-Amz-Security-Token", valid_595587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595588 = header.getOrDefault("X-Amz-Target")
  valid_595588 = validateParameter(valid_595588, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_595588 != nil:
    section.add "X-Amz-Target", valid_595588
  var valid_595589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595589 = validateParameter(valid_595589, JString, required = false,
                                 default = nil)
  if valid_595589 != nil:
    section.add "X-Amz-Content-Sha256", valid_595589
  var valid_595590 = header.getOrDefault("X-Amz-Algorithm")
  valid_595590 = validateParameter(valid_595590, JString, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "X-Amz-Algorithm", valid_595590
  var valid_595591 = header.getOrDefault("X-Amz-Signature")
  valid_595591 = validateParameter(valid_595591, JString, required = false,
                                 default = nil)
  if valid_595591 != nil:
    section.add "X-Amz-Signature", valid_595591
  var valid_595592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595592 = validateParameter(valid_595592, JString, required = false,
                                 default = nil)
  if valid_595592 != nil:
    section.add "X-Amz-SignedHeaders", valid_595592
  var valid_595593 = header.getOrDefault("X-Amz-Credential")
  valid_595593 = validateParameter(valid_595593, JString, required = false,
                                 default = nil)
  if valid_595593 != nil:
    section.add "X-Amz-Credential", valid_595593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595595: Call_StartImportLabelsTaskRun_595583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_595595.validator(path, query, header, formData, body)
  let scheme = call_595595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595595.url(scheme.get, call_595595.host, call_595595.base,
                         call_595595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595595, url, valid)

proc call*(call_595596: Call_StartImportLabelsTaskRun_595583; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_595597 = newJObject()
  if body != nil:
    body_595597 = body
  result = call_595596.call(nil, nil, nil, nil, body_595597)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_595583(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_595584, base: "/",
    url: url_StartImportLabelsTaskRun_595585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_595598 = ref object of OpenApiRestCall_593437
proc url_StartJobRun_595600(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartJobRun_595599(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a job run using a job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595601 = header.getOrDefault("X-Amz-Date")
  valid_595601 = validateParameter(valid_595601, JString, required = false,
                                 default = nil)
  if valid_595601 != nil:
    section.add "X-Amz-Date", valid_595601
  var valid_595602 = header.getOrDefault("X-Amz-Security-Token")
  valid_595602 = validateParameter(valid_595602, JString, required = false,
                                 default = nil)
  if valid_595602 != nil:
    section.add "X-Amz-Security-Token", valid_595602
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595603 = header.getOrDefault("X-Amz-Target")
  valid_595603 = validateParameter(valid_595603, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_595603 != nil:
    section.add "X-Amz-Target", valid_595603
  var valid_595604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "X-Amz-Content-Sha256", valid_595604
  var valid_595605 = header.getOrDefault("X-Amz-Algorithm")
  valid_595605 = validateParameter(valid_595605, JString, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "X-Amz-Algorithm", valid_595605
  var valid_595606 = header.getOrDefault("X-Amz-Signature")
  valid_595606 = validateParameter(valid_595606, JString, required = false,
                                 default = nil)
  if valid_595606 != nil:
    section.add "X-Amz-Signature", valid_595606
  var valid_595607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595607 = validateParameter(valid_595607, JString, required = false,
                                 default = nil)
  if valid_595607 != nil:
    section.add "X-Amz-SignedHeaders", valid_595607
  var valid_595608 = header.getOrDefault("X-Amz-Credential")
  valid_595608 = validateParameter(valid_595608, JString, required = false,
                                 default = nil)
  if valid_595608 != nil:
    section.add "X-Amz-Credential", valid_595608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595610: Call_StartJobRun_595598; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_595610.validator(path, query, header, formData, body)
  let scheme = call_595610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595610.url(scheme.get, call_595610.host, call_595610.base,
                         call_595610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595610, url, valid)

proc call*(call_595611: Call_StartJobRun_595598; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_595612 = newJObject()
  if body != nil:
    body_595612 = body
  result = call_595611.call(nil, nil, nil, nil, body_595612)

var startJobRun* = Call_StartJobRun_595598(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_595599,
                                        base: "/", url: url_StartJobRun_595600,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_595613 = ref object of OpenApiRestCall_593437
proc url_StartMLEvaluationTaskRun_595615(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLEvaluationTaskRun_595614(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595616 = header.getOrDefault("X-Amz-Date")
  valid_595616 = validateParameter(valid_595616, JString, required = false,
                                 default = nil)
  if valid_595616 != nil:
    section.add "X-Amz-Date", valid_595616
  var valid_595617 = header.getOrDefault("X-Amz-Security-Token")
  valid_595617 = validateParameter(valid_595617, JString, required = false,
                                 default = nil)
  if valid_595617 != nil:
    section.add "X-Amz-Security-Token", valid_595617
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595618 = header.getOrDefault("X-Amz-Target")
  valid_595618 = validateParameter(valid_595618, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_595618 != nil:
    section.add "X-Amz-Target", valid_595618
  var valid_595619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "X-Amz-Content-Sha256", valid_595619
  var valid_595620 = header.getOrDefault("X-Amz-Algorithm")
  valid_595620 = validateParameter(valid_595620, JString, required = false,
                                 default = nil)
  if valid_595620 != nil:
    section.add "X-Amz-Algorithm", valid_595620
  var valid_595621 = header.getOrDefault("X-Amz-Signature")
  valid_595621 = validateParameter(valid_595621, JString, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "X-Amz-Signature", valid_595621
  var valid_595622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "X-Amz-SignedHeaders", valid_595622
  var valid_595623 = header.getOrDefault("X-Amz-Credential")
  valid_595623 = validateParameter(valid_595623, JString, required = false,
                                 default = nil)
  if valid_595623 != nil:
    section.add "X-Amz-Credential", valid_595623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595625: Call_StartMLEvaluationTaskRun_595613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_595625.validator(path, query, header, formData, body)
  let scheme = call_595625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595625.url(scheme.get, call_595625.host, call_595625.base,
                         call_595625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595625, url, valid)

proc call*(call_595626: Call_StartMLEvaluationTaskRun_595613; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_595627 = newJObject()
  if body != nil:
    body_595627 = body
  result = call_595626.call(nil, nil, nil, nil, body_595627)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_595613(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_595614, base: "/",
    url: url_StartMLEvaluationTaskRun_595615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_595628 = ref object of OpenApiRestCall_593437
proc url_StartMLLabelingSetGenerationTaskRun_595630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_595629(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595631 = header.getOrDefault("X-Amz-Date")
  valid_595631 = validateParameter(valid_595631, JString, required = false,
                                 default = nil)
  if valid_595631 != nil:
    section.add "X-Amz-Date", valid_595631
  var valid_595632 = header.getOrDefault("X-Amz-Security-Token")
  valid_595632 = validateParameter(valid_595632, JString, required = false,
                                 default = nil)
  if valid_595632 != nil:
    section.add "X-Amz-Security-Token", valid_595632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595633 = header.getOrDefault("X-Amz-Target")
  valid_595633 = validateParameter(valid_595633, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_595633 != nil:
    section.add "X-Amz-Target", valid_595633
  var valid_595634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595634 = validateParameter(valid_595634, JString, required = false,
                                 default = nil)
  if valid_595634 != nil:
    section.add "X-Amz-Content-Sha256", valid_595634
  var valid_595635 = header.getOrDefault("X-Amz-Algorithm")
  valid_595635 = validateParameter(valid_595635, JString, required = false,
                                 default = nil)
  if valid_595635 != nil:
    section.add "X-Amz-Algorithm", valid_595635
  var valid_595636 = header.getOrDefault("X-Amz-Signature")
  valid_595636 = validateParameter(valid_595636, JString, required = false,
                                 default = nil)
  if valid_595636 != nil:
    section.add "X-Amz-Signature", valid_595636
  var valid_595637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595637 = validateParameter(valid_595637, JString, required = false,
                                 default = nil)
  if valid_595637 != nil:
    section.add "X-Amz-SignedHeaders", valid_595637
  var valid_595638 = header.getOrDefault("X-Amz-Credential")
  valid_595638 = validateParameter(valid_595638, JString, required = false,
                                 default = nil)
  if valid_595638 != nil:
    section.add "X-Amz-Credential", valid_595638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595640: Call_StartMLLabelingSetGenerationTaskRun_595628;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_595640.validator(path, query, header, formData, body)
  let scheme = call_595640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595640.url(scheme.get, call_595640.host, call_595640.base,
                         call_595640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595640, url, valid)

proc call*(call_595641: Call_StartMLLabelingSetGenerationTaskRun_595628;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_595642 = newJObject()
  if body != nil:
    body_595642 = body
  result = call_595641.call(nil, nil, nil, nil, body_595642)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_595628(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_595629, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_595630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_595643 = ref object of OpenApiRestCall_593437
proc url_StartTrigger_595645(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTrigger_595644(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595646 = header.getOrDefault("X-Amz-Date")
  valid_595646 = validateParameter(valid_595646, JString, required = false,
                                 default = nil)
  if valid_595646 != nil:
    section.add "X-Amz-Date", valid_595646
  var valid_595647 = header.getOrDefault("X-Amz-Security-Token")
  valid_595647 = validateParameter(valid_595647, JString, required = false,
                                 default = nil)
  if valid_595647 != nil:
    section.add "X-Amz-Security-Token", valid_595647
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595648 = header.getOrDefault("X-Amz-Target")
  valid_595648 = validateParameter(valid_595648, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_595648 != nil:
    section.add "X-Amz-Target", valid_595648
  var valid_595649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595649 = validateParameter(valid_595649, JString, required = false,
                                 default = nil)
  if valid_595649 != nil:
    section.add "X-Amz-Content-Sha256", valid_595649
  var valid_595650 = header.getOrDefault("X-Amz-Algorithm")
  valid_595650 = validateParameter(valid_595650, JString, required = false,
                                 default = nil)
  if valid_595650 != nil:
    section.add "X-Amz-Algorithm", valid_595650
  var valid_595651 = header.getOrDefault("X-Amz-Signature")
  valid_595651 = validateParameter(valid_595651, JString, required = false,
                                 default = nil)
  if valid_595651 != nil:
    section.add "X-Amz-Signature", valid_595651
  var valid_595652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595652 = validateParameter(valid_595652, JString, required = false,
                                 default = nil)
  if valid_595652 != nil:
    section.add "X-Amz-SignedHeaders", valid_595652
  var valid_595653 = header.getOrDefault("X-Amz-Credential")
  valid_595653 = validateParameter(valid_595653, JString, required = false,
                                 default = nil)
  if valid_595653 != nil:
    section.add "X-Amz-Credential", valid_595653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595655: Call_StartTrigger_595643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_595655.validator(path, query, header, formData, body)
  let scheme = call_595655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595655.url(scheme.get, call_595655.host, call_595655.base,
                         call_595655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595655, url, valid)

proc call*(call_595656: Call_StartTrigger_595643; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_595657 = newJObject()
  if body != nil:
    body_595657 = body
  result = call_595656.call(nil, nil, nil, nil, body_595657)

var startTrigger* = Call_StartTrigger_595643(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_595644, base: "/", url: url_StartTrigger_595645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_595658 = ref object of OpenApiRestCall_593437
proc url_StartWorkflowRun_595660(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkflowRun_595659(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Starts a new run of the specified workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595661 = header.getOrDefault("X-Amz-Date")
  valid_595661 = validateParameter(valid_595661, JString, required = false,
                                 default = nil)
  if valid_595661 != nil:
    section.add "X-Amz-Date", valid_595661
  var valid_595662 = header.getOrDefault("X-Amz-Security-Token")
  valid_595662 = validateParameter(valid_595662, JString, required = false,
                                 default = nil)
  if valid_595662 != nil:
    section.add "X-Amz-Security-Token", valid_595662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595663 = header.getOrDefault("X-Amz-Target")
  valid_595663 = validateParameter(valid_595663, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_595663 != nil:
    section.add "X-Amz-Target", valid_595663
  var valid_595664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595664 = validateParameter(valid_595664, JString, required = false,
                                 default = nil)
  if valid_595664 != nil:
    section.add "X-Amz-Content-Sha256", valid_595664
  var valid_595665 = header.getOrDefault("X-Amz-Algorithm")
  valid_595665 = validateParameter(valid_595665, JString, required = false,
                                 default = nil)
  if valid_595665 != nil:
    section.add "X-Amz-Algorithm", valid_595665
  var valid_595666 = header.getOrDefault("X-Amz-Signature")
  valid_595666 = validateParameter(valid_595666, JString, required = false,
                                 default = nil)
  if valid_595666 != nil:
    section.add "X-Amz-Signature", valid_595666
  var valid_595667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595667 = validateParameter(valid_595667, JString, required = false,
                                 default = nil)
  if valid_595667 != nil:
    section.add "X-Amz-SignedHeaders", valid_595667
  var valid_595668 = header.getOrDefault("X-Amz-Credential")
  valid_595668 = validateParameter(valid_595668, JString, required = false,
                                 default = nil)
  if valid_595668 != nil:
    section.add "X-Amz-Credential", valid_595668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595670: Call_StartWorkflowRun_595658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_595670.validator(path, query, header, formData, body)
  let scheme = call_595670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595670.url(scheme.get, call_595670.host, call_595670.base,
                         call_595670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595670, url, valid)

proc call*(call_595671: Call_StartWorkflowRun_595658; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_595672 = newJObject()
  if body != nil:
    body_595672 = body
  result = call_595671.call(nil, nil, nil, nil, body_595672)

var startWorkflowRun* = Call_StartWorkflowRun_595658(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_595659, base: "/",
    url: url_StartWorkflowRun_595660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_595673 = ref object of OpenApiRestCall_593437
proc url_StopCrawler_595675(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawler_595674(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## If the specified crawler is running, stops the crawl.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595676 = header.getOrDefault("X-Amz-Date")
  valid_595676 = validateParameter(valid_595676, JString, required = false,
                                 default = nil)
  if valid_595676 != nil:
    section.add "X-Amz-Date", valid_595676
  var valid_595677 = header.getOrDefault("X-Amz-Security-Token")
  valid_595677 = validateParameter(valid_595677, JString, required = false,
                                 default = nil)
  if valid_595677 != nil:
    section.add "X-Amz-Security-Token", valid_595677
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595678 = header.getOrDefault("X-Amz-Target")
  valid_595678 = validateParameter(valid_595678, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_595678 != nil:
    section.add "X-Amz-Target", valid_595678
  var valid_595679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595679 = validateParameter(valid_595679, JString, required = false,
                                 default = nil)
  if valid_595679 != nil:
    section.add "X-Amz-Content-Sha256", valid_595679
  var valid_595680 = header.getOrDefault("X-Amz-Algorithm")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "X-Amz-Algorithm", valid_595680
  var valid_595681 = header.getOrDefault("X-Amz-Signature")
  valid_595681 = validateParameter(valid_595681, JString, required = false,
                                 default = nil)
  if valid_595681 != nil:
    section.add "X-Amz-Signature", valid_595681
  var valid_595682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595682 = validateParameter(valid_595682, JString, required = false,
                                 default = nil)
  if valid_595682 != nil:
    section.add "X-Amz-SignedHeaders", valid_595682
  var valid_595683 = header.getOrDefault("X-Amz-Credential")
  valid_595683 = validateParameter(valid_595683, JString, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "X-Amz-Credential", valid_595683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595685: Call_StopCrawler_595673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_595685.validator(path, query, header, formData, body)
  let scheme = call_595685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595685.url(scheme.get, call_595685.host, call_595685.base,
                         call_595685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595685, url, valid)

proc call*(call_595686: Call_StopCrawler_595673; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_595687 = newJObject()
  if body != nil:
    body_595687 = body
  result = call_595686.call(nil, nil, nil, nil, body_595687)

var stopCrawler* = Call_StopCrawler_595673(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_595674,
                                        base: "/", url: url_StopCrawler_595675,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_595688 = ref object of OpenApiRestCall_593437
proc url_StopCrawlerSchedule_595690(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawlerSchedule_595689(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595691 = header.getOrDefault("X-Amz-Date")
  valid_595691 = validateParameter(valid_595691, JString, required = false,
                                 default = nil)
  if valid_595691 != nil:
    section.add "X-Amz-Date", valid_595691
  var valid_595692 = header.getOrDefault("X-Amz-Security-Token")
  valid_595692 = validateParameter(valid_595692, JString, required = false,
                                 default = nil)
  if valid_595692 != nil:
    section.add "X-Amz-Security-Token", valid_595692
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595693 = header.getOrDefault("X-Amz-Target")
  valid_595693 = validateParameter(valid_595693, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_595693 != nil:
    section.add "X-Amz-Target", valid_595693
  var valid_595694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595694 = validateParameter(valid_595694, JString, required = false,
                                 default = nil)
  if valid_595694 != nil:
    section.add "X-Amz-Content-Sha256", valid_595694
  var valid_595695 = header.getOrDefault("X-Amz-Algorithm")
  valid_595695 = validateParameter(valid_595695, JString, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "X-Amz-Algorithm", valid_595695
  var valid_595696 = header.getOrDefault("X-Amz-Signature")
  valid_595696 = validateParameter(valid_595696, JString, required = false,
                                 default = nil)
  if valid_595696 != nil:
    section.add "X-Amz-Signature", valid_595696
  var valid_595697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595697 = validateParameter(valid_595697, JString, required = false,
                                 default = nil)
  if valid_595697 != nil:
    section.add "X-Amz-SignedHeaders", valid_595697
  var valid_595698 = header.getOrDefault("X-Amz-Credential")
  valid_595698 = validateParameter(valid_595698, JString, required = false,
                                 default = nil)
  if valid_595698 != nil:
    section.add "X-Amz-Credential", valid_595698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595700: Call_StopCrawlerSchedule_595688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_595700.validator(path, query, header, formData, body)
  let scheme = call_595700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595700.url(scheme.get, call_595700.host, call_595700.base,
                         call_595700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595700, url, valid)

proc call*(call_595701: Call_StopCrawlerSchedule_595688; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_595702 = newJObject()
  if body != nil:
    body_595702 = body
  result = call_595701.call(nil, nil, nil, nil, body_595702)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_595688(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_595689, base: "/",
    url: url_StopCrawlerSchedule_595690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_595703 = ref object of OpenApiRestCall_593437
proc url_StopTrigger_595705(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrigger_595704(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a specified trigger.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595706 = header.getOrDefault("X-Amz-Date")
  valid_595706 = validateParameter(valid_595706, JString, required = false,
                                 default = nil)
  if valid_595706 != nil:
    section.add "X-Amz-Date", valid_595706
  var valid_595707 = header.getOrDefault("X-Amz-Security-Token")
  valid_595707 = validateParameter(valid_595707, JString, required = false,
                                 default = nil)
  if valid_595707 != nil:
    section.add "X-Amz-Security-Token", valid_595707
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595708 = header.getOrDefault("X-Amz-Target")
  valid_595708 = validateParameter(valid_595708, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_595708 != nil:
    section.add "X-Amz-Target", valid_595708
  var valid_595709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595709 = validateParameter(valid_595709, JString, required = false,
                                 default = nil)
  if valid_595709 != nil:
    section.add "X-Amz-Content-Sha256", valid_595709
  var valid_595710 = header.getOrDefault("X-Amz-Algorithm")
  valid_595710 = validateParameter(valid_595710, JString, required = false,
                                 default = nil)
  if valid_595710 != nil:
    section.add "X-Amz-Algorithm", valid_595710
  var valid_595711 = header.getOrDefault("X-Amz-Signature")
  valid_595711 = validateParameter(valid_595711, JString, required = false,
                                 default = nil)
  if valid_595711 != nil:
    section.add "X-Amz-Signature", valid_595711
  var valid_595712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595712 = validateParameter(valid_595712, JString, required = false,
                                 default = nil)
  if valid_595712 != nil:
    section.add "X-Amz-SignedHeaders", valid_595712
  var valid_595713 = header.getOrDefault("X-Amz-Credential")
  valid_595713 = validateParameter(valid_595713, JString, required = false,
                                 default = nil)
  if valid_595713 != nil:
    section.add "X-Amz-Credential", valid_595713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595715: Call_StopTrigger_595703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_595715.validator(path, query, header, formData, body)
  let scheme = call_595715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595715.url(scheme.get, call_595715.host, call_595715.base,
                         call_595715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595715, url, valid)

proc call*(call_595716: Call_StopTrigger_595703; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_595717 = newJObject()
  if body != nil:
    body_595717 = body
  result = call_595716.call(nil, nil, nil, nil, body_595717)

var stopTrigger* = Call_StopTrigger_595703(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_595704,
                                        base: "/", url: url_StopTrigger_595705,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_595718 = ref object of OpenApiRestCall_593437
proc url_TagResource_595720(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_595719(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595721 = header.getOrDefault("X-Amz-Date")
  valid_595721 = validateParameter(valid_595721, JString, required = false,
                                 default = nil)
  if valid_595721 != nil:
    section.add "X-Amz-Date", valid_595721
  var valid_595722 = header.getOrDefault("X-Amz-Security-Token")
  valid_595722 = validateParameter(valid_595722, JString, required = false,
                                 default = nil)
  if valid_595722 != nil:
    section.add "X-Amz-Security-Token", valid_595722
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595723 = header.getOrDefault("X-Amz-Target")
  valid_595723 = validateParameter(valid_595723, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_595723 != nil:
    section.add "X-Amz-Target", valid_595723
  var valid_595724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595724 = validateParameter(valid_595724, JString, required = false,
                                 default = nil)
  if valid_595724 != nil:
    section.add "X-Amz-Content-Sha256", valid_595724
  var valid_595725 = header.getOrDefault("X-Amz-Algorithm")
  valid_595725 = validateParameter(valid_595725, JString, required = false,
                                 default = nil)
  if valid_595725 != nil:
    section.add "X-Amz-Algorithm", valid_595725
  var valid_595726 = header.getOrDefault("X-Amz-Signature")
  valid_595726 = validateParameter(valid_595726, JString, required = false,
                                 default = nil)
  if valid_595726 != nil:
    section.add "X-Amz-Signature", valid_595726
  var valid_595727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595727 = validateParameter(valid_595727, JString, required = false,
                                 default = nil)
  if valid_595727 != nil:
    section.add "X-Amz-SignedHeaders", valid_595727
  var valid_595728 = header.getOrDefault("X-Amz-Credential")
  valid_595728 = validateParameter(valid_595728, JString, required = false,
                                 default = nil)
  if valid_595728 != nil:
    section.add "X-Amz-Credential", valid_595728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595730: Call_TagResource_595718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_595730.validator(path, query, header, formData, body)
  let scheme = call_595730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595730.url(scheme.get, call_595730.host, call_595730.base,
                         call_595730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595730, url, valid)

proc call*(call_595731: Call_TagResource_595718; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_595732 = newJObject()
  if body != nil:
    body_595732 = body
  result = call_595731.call(nil, nil, nil, nil, body_595732)

var tagResource* = Call_TagResource_595718(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_595719,
                                        base: "/", url: url_TagResource_595720,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_595733 = ref object of OpenApiRestCall_593437
proc url_UntagResource_595735(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_595734(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595736 = header.getOrDefault("X-Amz-Date")
  valid_595736 = validateParameter(valid_595736, JString, required = false,
                                 default = nil)
  if valid_595736 != nil:
    section.add "X-Amz-Date", valid_595736
  var valid_595737 = header.getOrDefault("X-Amz-Security-Token")
  valid_595737 = validateParameter(valid_595737, JString, required = false,
                                 default = nil)
  if valid_595737 != nil:
    section.add "X-Amz-Security-Token", valid_595737
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595738 = header.getOrDefault("X-Amz-Target")
  valid_595738 = validateParameter(valid_595738, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_595738 != nil:
    section.add "X-Amz-Target", valid_595738
  var valid_595739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595739 = validateParameter(valid_595739, JString, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "X-Amz-Content-Sha256", valid_595739
  var valid_595740 = header.getOrDefault("X-Amz-Algorithm")
  valid_595740 = validateParameter(valid_595740, JString, required = false,
                                 default = nil)
  if valid_595740 != nil:
    section.add "X-Amz-Algorithm", valid_595740
  var valid_595741 = header.getOrDefault("X-Amz-Signature")
  valid_595741 = validateParameter(valid_595741, JString, required = false,
                                 default = nil)
  if valid_595741 != nil:
    section.add "X-Amz-Signature", valid_595741
  var valid_595742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595742 = validateParameter(valid_595742, JString, required = false,
                                 default = nil)
  if valid_595742 != nil:
    section.add "X-Amz-SignedHeaders", valid_595742
  var valid_595743 = header.getOrDefault("X-Amz-Credential")
  valid_595743 = validateParameter(valid_595743, JString, required = false,
                                 default = nil)
  if valid_595743 != nil:
    section.add "X-Amz-Credential", valid_595743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595745: Call_UntagResource_595733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_595745.validator(path, query, header, formData, body)
  let scheme = call_595745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595745.url(scheme.get, call_595745.host, call_595745.base,
                         call_595745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595745, url, valid)

proc call*(call_595746: Call_UntagResource_595733; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_595747 = newJObject()
  if body != nil:
    body_595747 = body
  result = call_595746.call(nil, nil, nil, nil, body_595747)

var untagResource* = Call_UntagResource_595733(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_595734, base: "/", url: url_UntagResource_595735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_595748 = ref object of OpenApiRestCall_593437
proc url_UpdateClassifier_595750(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateClassifier_595749(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595751 = header.getOrDefault("X-Amz-Date")
  valid_595751 = validateParameter(valid_595751, JString, required = false,
                                 default = nil)
  if valid_595751 != nil:
    section.add "X-Amz-Date", valid_595751
  var valid_595752 = header.getOrDefault("X-Amz-Security-Token")
  valid_595752 = validateParameter(valid_595752, JString, required = false,
                                 default = nil)
  if valid_595752 != nil:
    section.add "X-Amz-Security-Token", valid_595752
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595753 = header.getOrDefault("X-Amz-Target")
  valid_595753 = validateParameter(valid_595753, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_595753 != nil:
    section.add "X-Amz-Target", valid_595753
  var valid_595754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595754 = validateParameter(valid_595754, JString, required = false,
                                 default = nil)
  if valid_595754 != nil:
    section.add "X-Amz-Content-Sha256", valid_595754
  var valid_595755 = header.getOrDefault("X-Amz-Algorithm")
  valid_595755 = validateParameter(valid_595755, JString, required = false,
                                 default = nil)
  if valid_595755 != nil:
    section.add "X-Amz-Algorithm", valid_595755
  var valid_595756 = header.getOrDefault("X-Amz-Signature")
  valid_595756 = validateParameter(valid_595756, JString, required = false,
                                 default = nil)
  if valid_595756 != nil:
    section.add "X-Amz-Signature", valid_595756
  var valid_595757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595757 = validateParameter(valid_595757, JString, required = false,
                                 default = nil)
  if valid_595757 != nil:
    section.add "X-Amz-SignedHeaders", valid_595757
  var valid_595758 = header.getOrDefault("X-Amz-Credential")
  valid_595758 = validateParameter(valid_595758, JString, required = false,
                                 default = nil)
  if valid_595758 != nil:
    section.add "X-Amz-Credential", valid_595758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595760: Call_UpdateClassifier_595748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_595760.validator(path, query, header, formData, body)
  let scheme = call_595760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595760.url(scheme.get, call_595760.host, call_595760.base,
                         call_595760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595760, url, valid)

proc call*(call_595761: Call_UpdateClassifier_595748; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_595762 = newJObject()
  if body != nil:
    body_595762 = body
  result = call_595761.call(nil, nil, nil, nil, body_595762)

var updateClassifier* = Call_UpdateClassifier_595748(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_595749, base: "/",
    url: url_UpdateClassifier_595750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_595763 = ref object of OpenApiRestCall_593437
proc url_UpdateConnection_595765(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConnection_595764(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a connection definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595766 = header.getOrDefault("X-Amz-Date")
  valid_595766 = validateParameter(valid_595766, JString, required = false,
                                 default = nil)
  if valid_595766 != nil:
    section.add "X-Amz-Date", valid_595766
  var valid_595767 = header.getOrDefault("X-Amz-Security-Token")
  valid_595767 = validateParameter(valid_595767, JString, required = false,
                                 default = nil)
  if valid_595767 != nil:
    section.add "X-Amz-Security-Token", valid_595767
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595768 = header.getOrDefault("X-Amz-Target")
  valid_595768 = validateParameter(valid_595768, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_595768 != nil:
    section.add "X-Amz-Target", valid_595768
  var valid_595769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595769 = validateParameter(valid_595769, JString, required = false,
                                 default = nil)
  if valid_595769 != nil:
    section.add "X-Amz-Content-Sha256", valid_595769
  var valid_595770 = header.getOrDefault("X-Amz-Algorithm")
  valid_595770 = validateParameter(valid_595770, JString, required = false,
                                 default = nil)
  if valid_595770 != nil:
    section.add "X-Amz-Algorithm", valid_595770
  var valid_595771 = header.getOrDefault("X-Amz-Signature")
  valid_595771 = validateParameter(valid_595771, JString, required = false,
                                 default = nil)
  if valid_595771 != nil:
    section.add "X-Amz-Signature", valid_595771
  var valid_595772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595772 = validateParameter(valid_595772, JString, required = false,
                                 default = nil)
  if valid_595772 != nil:
    section.add "X-Amz-SignedHeaders", valid_595772
  var valid_595773 = header.getOrDefault("X-Amz-Credential")
  valid_595773 = validateParameter(valid_595773, JString, required = false,
                                 default = nil)
  if valid_595773 != nil:
    section.add "X-Amz-Credential", valid_595773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595775: Call_UpdateConnection_595763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_595775.validator(path, query, header, formData, body)
  let scheme = call_595775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595775.url(scheme.get, call_595775.host, call_595775.base,
                         call_595775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595775, url, valid)

proc call*(call_595776: Call_UpdateConnection_595763; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_595777 = newJObject()
  if body != nil:
    body_595777 = body
  result = call_595776.call(nil, nil, nil, nil, body_595777)

var updateConnection* = Call_UpdateConnection_595763(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_595764, base: "/",
    url: url_UpdateConnection_595765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_595778 = ref object of OpenApiRestCall_593437
proc url_UpdateCrawler_595780(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawler_595779(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595781 = header.getOrDefault("X-Amz-Date")
  valid_595781 = validateParameter(valid_595781, JString, required = false,
                                 default = nil)
  if valid_595781 != nil:
    section.add "X-Amz-Date", valid_595781
  var valid_595782 = header.getOrDefault("X-Amz-Security-Token")
  valid_595782 = validateParameter(valid_595782, JString, required = false,
                                 default = nil)
  if valid_595782 != nil:
    section.add "X-Amz-Security-Token", valid_595782
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595783 = header.getOrDefault("X-Amz-Target")
  valid_595783 = validateParameter(valid_595783, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_595783 != nil:
    section.add "X-Amz-Target", valid_595783
  var valid_595784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595784 = validateParameter(valid_595784, JString, required = false,
                                 default = nil)
  if valid_595784 != nil:
    section.add "X-Amz-Content-Sha256", valid_595784
  var valid_595785 = header.getOrDefault("X-Amz-Algorithm")
  valid_595785 = validateParameter(valid_595785, JString, required = false,
                                 default = nil)
  if valid_595785 != nil:
    section.add "X-Amz-Algorithm", valid_595785
  var valid_595786 = header.getOrDefault("X-Amz-Signature")
  valid_595786 = validateParameter(valid_595786, JString, required = false,
                                 default = nil)
  if valid_595786 != nil:
    section.add "X-Amz-Signature", valid_595786
  var valid_595787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595787 = validateParameter(valid_595787, JString, required = false,
                                 default = nil)
  if valid_595787 != nil:
    section.add "X-Amz-SignedHeaders", valid_595787
  var valid_595788 = header.getOrDefault("X-Amz-Credential")
  valid_595788 = validateParameter(valid_595788, JString, required = false,
                                 default = nil)
  if valid_595788 != nil:
    section.add "X-Amz-Credential", valid_595788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595790: Call_UpdateCrawler_595778; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_595790.validator(path, query, header, formData, body)
  let scheme = call_595790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595790.url(scheme.get, call_595790.host, call_595790.base,
                         call_595790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595790, url, valid)

proc call*(call_595791: Call_UpdateCrawler_595778; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_595792 = newJObject()
  if body != nil:
    body_595792 = body
  result = call_595791.call(nil, nil, nil, nil, body_595792)

var updateCrawler* = Call_UpdateCrawler_595778(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_595779, base: "/", url: url_UpdateCrawler_595780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_595793 = ref object of OpenApiRestCall_593437
proc url_UpdateCrawlerSchedule_595795(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawlerSchedule_595794(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595796 = header.getOrDefault("X-Amz-Date")
  valid_595796 = validateParameter(valid_595796, JString, required = false,
                                 default = nil)
  if valid_595796 != nil:
    section.add "X-Amz-Date", valid_595796
  var valid_595797 = header.getOrDefault("X-Amz-Security-Token")
  valid_595797 = validateParameter(valid_595797, JString, required = false,
                                 default = nil)
  if valid_595797 != nil:
    section.add "X-Amz-Security-Token", valid_595797
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595798 = header.getOrDefault("X-Amz-Target")
  valid_595798 = validateParameter(valid_595798, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_595798 != nil:
    section.add "X-Amz-Target", valid_595798
  var valid_595799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595799 = validateParameter(valid_595799, JString, required = false,
                                 default = nil)
  if valid_595799 != nil:
    section.add "X-Amz-Content-Sha256", valid_595799
  var valid_595800 = header.getOrDefault("X-Amz-Algorithm")
  valid_595800 = validateParameter(valid_595800, JString, required = false,
                                 default = nil)
  if valid_595800 != nil:
    section.add "X-Amz-Algorithm", valid_595800
  var valid_595801 = header.getOrDefault("X-Amz-Signature")
  valid_595801 = validateParameter(valid_595801, JString, required = false,
                                 default = nil)
  if valid_595801 != nil:
    section.add "X-Amz-Signature", valid_595801
  var valid_595802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595802 = validateParameter(valid_595802, JString, required = false,
                                 default = nil)
  if valid_595802 != nil:
    section.add "X-Amz-SignedHeaders", valid_595802
  var valid_595803 = header.getOrDefault("X-Amz-Credential")
  valid_595803 = validateParameter(valid_595803, JString, required = false,
                                 default = nil)
  if valid_595803 != nil:
    section.add "X-Amz-Credential", valid_595803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595805: Call_UpdateCrawlerSchedule_595793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_595805.validator(path, query, header, formData, body)
  let scheme = call_595805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595805.url(scheme.get, call_595805.host, call_595805.base,
                         call_595805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595805, url, valid)

proc call*(call_595806: Call_UpdateCrawlerSchedule_595793; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_595807 = newJObject()
  if body != nil:
    body_595807 = body
  result = call_595806.call(nil, nil, nil, nil, body_595807)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_595793(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_595794, base: "/",
    url: url_UpdateCrawlerSchedule_595795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_595808 = ref object of OpenApiRestCall_593437
proc url_UpdateDatabase_595810(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDatabase_595809(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing database definition in a Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595811 = header.getOrDefault("X-Amz-Date")
  valid_595811 = validateParameter(valid_595811, JString, required = false,
                                 default = nil)
  if valid_595811 != nil:
    section.add "X-Amz-Date", valid_595811
  var valid_595812 = header.getOrDefault("X-Amz-Security-Token")
  valid_595812 = validateParameter(valid_595812, JString, required = false,
                                 default = nil)
  if valid_595812 != nil:
    section.add "X-Amz-Security-Token", valid_595812
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595813 = header.getOrDefault("X-Amz-Target")
  valid_595813 = validateParameter(valid_595813, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_595813 != nil:
    section.add "X-Amz-Target", valid_595813
  var valid_595814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595814 = validateParameter(valid_595814, JString, required = false,
                                 default = nil)
  if valid_595814 != nil:
    section.add "X-Amz-Content-Sha256", valid_595814
  var valid_595815 = header.getOrDefault("X-Amz-Algorithm")
  valid_595815 = validateParameter(valid_595815, JString, required = false,
                                 default = nil)
  if valid_595815 != nil:
    section.add "X-Amz-Algorithm", valid_595815
  var valid_595816 = header.getOrDefault("X-Amz-Signature")
  valid_595816 = validateParameter(valid_595816, JString, required = false,
                                 default = nil)
  if valid_595816 != nil:
    section.add "X-Amz-Signature", valid_595816
  var valid_595817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595817 = validateParameter(valid_595817, JString, required = false,
                                 default = nil)
  if valid_595817 != nil:
    section.add "X-Amz-SignedHeaders", valid_595817
  var valid_595818 = header.getOrDefault("X-Amz-Credential")
  valid_595818 = validateParameter(valid_595818, JString, required = false,
                                 default = nil)
  if valid_595818 != nil:
    section.add "X-Amz-Credential", valid_595818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595820: Call_UpdateDatabase_595808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_595820.validator(path, query, header, formData, body)
  let scheme = call_595820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595820.url(scheme.get, call_595820.host, call_595820.base,
                         call_595820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595820, url, valid)

proc call*(call_595821: Call_UpdateDatabase_595808; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_595822 = newJObject()
  if body != nil:
    body_595822 = body
  result = call_595821.call(nil, nil, nil, nil, body_595822)

var updateDatabase* = Call_UpdateDatabase_595808(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_595809, base: "/", url: url_UpdateDatabase_595810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_595823 = ref object of OpenApiRestCall_593437
proc url_UpdateDevEndpoint_595825(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevEndpoint_595824(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates a specified development endpoint.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595826 = header.getOrDefault("X-Amz-Date")
  valid_595826 = validateParameter(valid_595826, JString, required = false,
                                 default = nil)
  if valid_595826 != nil:
    section.add "X-Amz-Date", valid_595826
  var valid_595827 = header.getOrDefault("X-Amz-Security-Token")
  valid_595827 = validateParameter(valid_595827, JString, required = false,
                                 default = nil)
  if valid_595827 != nil:
    section.add "X-Amz-Security-Token", valid_595827
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595828 = header.getOrDefault("X-Amz-Target")
  valid_595828 = validateParameter(valid_595828, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_595828 != nil:
    section.add "X-Amz-Target", valid_595828
  var valid_595829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595829 = validateParameter(valid_595829, JString, required = false,
                                 default = nil)
  if valid_595829 != nil:
    section.add "X-Amz-Content-Sha256", valid_595829
  var valid_595830 = header.getOrDefault("X-Amz-Algorithm")
  valid_595830 = validateParameter(valid_595830, JString, required = false,
                                 default = nil)
  if valid_595830 != nil:
    section.add "X-Amz-Algorithm", valid_595830
  var valid_595831 = header.getOrDefault("X-Amz-Signature")
  valid_595831 = validateParameter(valid_595831, JString, required = false,
                                 default = nil)
  if valid_595831 != nil:
    section.add "X-Amz-Signature", valid_595831
  var valid_595832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595832 = validateParameter(valid_595832, JString, required = false,
                                 default = nil)
  if valid_595832 != nil:
    section.add "X-Amz-SignedHeaders", valid_595832
  var valid_595833 = header.getOrDefault("X-Amz-Credential")
  valid_595833 = validateParameter(valid_595833, JString, required = false,
                                 default = nil)
  if valid_595833 != nil:
    section.add "X-Amz-Credential", valid_595833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595835: Call_UpdateDevEndpoint_595823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_595835.validator(path, query, header, formData, body)
  let scheme = call_595835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595835.url(scheme.get, call_595835.host, call_595835.base,
                         call_595835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595835, url, valid)

proc call*(call_595836: Call_UpdateDevEndpoint_595823; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_595837 = newJObject()
  if body != nil:
    body_595837 = body
  result = call_595836.call(nil, nil, nil, nil, body_595837)

var updateDevEndpoint* = Call_UpdateDevEndpoint_595823(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_595824, base: "/",
    url: url_UpdateDevEndpoint_595825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_595838 = ref object of OpenApiRestCall_593437
proc url_UpdateJob_595840(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateJob_595839(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing job definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595841 = header.getOrDefault("X-Amz-Date")
  valid_595841 = validateParameter(valid_595841, JString, required = false,
                                 default = nil)
  if valid_595841 != nil:
    section.add "X-Amz-Date", valid_595841
  var valid_595842 = header.getOrDefault("X-Amz-Security-Token")
  valid_595842 = validateParameter(valid_595842, JString, required = false,
                                 default = nil)
  if valid_595842 != nil:
    section.add "X-Amz-Security-Token", valid_595842
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595843 = header.getOrDefault("X-Amz-Target")
  valid_595843 = validateParameter(valid_595843, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_595843 != nil:
    section.add "X-Amz-Target", valid_595843
  var valid_595844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595844 = validateParameter(valid_595844, JString, required = false,
                                 default = nil)
  if valid_595844 != nil:
    section.add "X-Amz-Content-Sha256", valid_595844
  var valid_595845 = header.getOrDefault("X-Amz-Algorithm")
  valid_595845 = validateParameter(valid_595845, JString, required = false,
                                 default = nil)
  if valid_595845 != nil:
    section.add "X-Amz-Algorithm", valid_595845
  var valid_595846 = header.getOrDefault("X-Amz-Signature")
  valid_595846 = validateParameter(valid_595846, JString, required = false,
                                 default = nil)
  if valid_595846 != nil:
    section.add "X-Amz-Signature", valid_595846
  var valid_595847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595847 = validateParameter(valid_595847, JString, required = false,
                                 default = nil)
  if valid_595847 != nil:
    section.add "X-Amz-SignedHeaders", valid_595847
  var valid_595848 = header.getOrDefault("X-Amz-Credential")
  valid_595848 = validateParameter(valid_595848, JString, required = false,
                                 default = nil)
  if valid_595848 != nil:
    section.add "X-Amz-Credential", valid_595848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595850: Call_UpdateJob_595838; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_595850.validator(path, query, header, formData, body)
  let scheme = call_595850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595850.url(scheme.get, call_595850.host, call_595850.base,
                         call_595850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595850, url, valid)

proc call*(call_595851: Call_UpdateJob_595838; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_595852 = newJObject()
  if body != nil:
    body_595852 = body
  result = call_595851.call(nil, nil, nil, nil, body_595852)

var updateJob* = Call_UpdateJob_595838(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_595839,
                                    base: "/", url: url_UpdateJob_595840,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_595853 = ref object of OpenApiRestCall_593437
proc url_UpdateMLTransform_595855(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMLTransform_595854(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595856 = header.getOrDefault("X-Amz-Date")
  valid_595856 = validateParameter(valid_595856, JString, required = false,
                                 default = nil)
  if valid_595856 != nil:
    section.add "X-Amz-Date", valid_595856
  var valid_595857 = header.getOrDefault("X-Amz-Security-Token")
  valid_595857 = validateParameter(valid_595857, JString, required = false,
                                 default = nil)
  if valid_595857 != nil:
    section.add "X-Amz-Security-Token", valid_595857
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595858 = header.getOrDefault("X-Amz-Target")
  valid_595858 = validateParameter(valid_595858, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_595858 != nil:
    section.add "X-Amz-Target", valid_595858
  var valid_595859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595859 = validateParameter(valid_595859, JString, required = false,
                                 default = nil)
  if valid_595859 != nil:
    section.add "X-Amz-Content-Sha256", valid_595859
  var valid_595860 = header.getOrDefault("X-Amz-Algorithm")
  valid_595860 = validateParameter(valid_595860, JString, required = false,
                                 default = nil)
  if valid_595860 != nil:
    section.add "X-Amz-Algorithm", valid_595860
  var valid_595861 = header.getOrDefault("X-Amz-Signature")
  valid_595861 = validateParameter(valid_595861, JString, required = false,
                                 default = nil)
  if valid_595861 != nil:
    section.add "X-Amz-Signature", valid_595861
  var valid_595862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595862 = validateParameter(valid_595862, JString, required = false,
                                 default = nil)
  if valid_595862 != nil:
    section.add "X-Amz-SignedHeaders", valid_595862
  var valid_595863 = header.getOrDefault("X-Amz-Credential")
  valid_595863 = validateParameter(valid_595863, JString, required = false,
                                 default = nil)
  if valid_595863 != nil:
    section.add "X-Amz-Credential", valid_595863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595865: Call_UpdateMLTransform_595853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_595865.validator(path, query, header, formData, body)
  let scheme = call_595865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595865.url(scheme.get, call_595865.host, call_595865.base,
                         call_595865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595865, url, valid)

proc call*(call_595866: Call_UpdateMLTransform_595853; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_595867 = newJObject()
  if body != nil:
    body_595867 = body
  result = call_595866.call(nil, nil, nil, nil, body_595867)

var updateMLTransform* = Call_UpdateMLTransform_595853(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_595854, base: "/",
    url: url_UpdateMLTransform_595855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_595868 = ref object of OpenApiRestCall_593437
proc url_UpdatePartition_595870(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePartition_595869(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a partition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595871 = header.getOrDefault("X-Amz-Date")
  valid_595871 = validateParameter(valid_595871, JString, required = false,
                                 default = nil)
  if valid_595871 != nil:
    section.add "X-Amz-Date", valid_595871
  var valid_595872 = header.getOrDefault("X-Amz-Security-Token")
  valid_595872 = validateParameter(valid_595872, JString, required = false,
                                 default = nil)
  if valid_595872 != nil:
    section.add "X-Amz-Security-Token", valid_595872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595873 = header.getOrDefault("X-Amz-Target")
  valid_595873 = validateParameter(valid_595873, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_595873 != nil:
    section.add "X-Amz-Target", valid_595873
  var valid_595874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595874 = validateParameter(valid_595874, JString, required = false,
                                 default = nil)
  if valid_595874 != nil:
    section.add "X-Amz-Content-Sha256", valid_595874
  var valid_595875 = header.getOrDefault("X-Amz-Algorithm")
  valid_595875 = validateParameter(valid_595875, JString, required = false,
                                 default = nil)
  if valid_595875 != nil:
    section.add "X-Amz-Algorithm", valid_595875
  var valid_595876 = header.getOrDefault("X-Amz-Signature")
  valid_595876 = validateParameter(valid_595876, JString, required = false,
                                 default = nil)
  if valid_595876 != nil:
    section.add "X-Amz-Signature", valid_595876
  var valid_595877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595877 = validateParameter(valid_595877, JString, required = false,
                                 default = nil)
  if valid_595877 != nil:
    section.add "X-Amz-SignedHeaders", valid_595877
  var valid_595878 = header.getOrDefault("X-Amz-Credential")
  valid_595878 = validateParameter(valid_595878, JString, required = false,
                                 default = nil)
  if valid_595878 != nil:
    section.add "X-Amz-Credential", valid_595878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595880: Call_UpdatePartition_595868; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_595880.validator(path, query, header, formData, body)
  let scheme = call_595880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595880.url(scheme.get, call_595880.host, call_595880.base,
                         call_595880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595880, url, valid)

proc call*(call_595881: Call_UpdatePartition_595868; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_595882 = newJObject()
  if body != nil:
    body_595882 = body
  result = call_595881.call(nil, nil, nil, nil, body_595882)

var updatePartition* = Call_UpdatePartition_595868(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_595869, base: "/", url: url_UpdatePartition_595870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_595883 = ref object of OpenApiRestCall_593437
proc url_UpdateTable_595885(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTable_595884(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a metadata table in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595886 = header.getOrDefault("X-Amz-Date")
  valid_595886 = validateParameter(valid_595886, JString, required = false,
                                 default = nil)
  if valid_595886 != nil:
    section.add "X-Amz-Date", valid_595886
  var valid_595887 = header.getOrDefault("X-Amz-Security-Token")
  valid_595887 = validateParameter(valid_595887, JString, required = false,
                                 default = nil)
  if valid_595887 != nil:
    section.add "X-Amz-Security-Token", valid_595887
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595888 = header.getOrDefault("X-Amz-Target")
  valid_595888 = validateParameter(valid_595888, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_595888 != nil:
    section.add "X-Amz-Target", valid_595888
  var valid_595889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595889 = validateParameter(valid_595889, JString, required = false,
                                 default = nil)
  if valid_595889 != nil:
    section.add "X-Amz-Content-Sha256", valid_595889
  var valid_595890 = header.getOrDefault("X-Amz-Algorithm")
  valid_595890 = validateParameter(valid_595890, JString, required = false,
                                 default = nil)
  if valid_595890 != nil:
    section.add "X-Amz-Algorithm", valid_595890
  var valid_595891 = header.getOrDefault("X-Amz-Signature")
  valid_595891 = validateParameter(valid_595891, JString, required = false,
                                 default = nil)
  if valid_595891 != nil:
    section.add "X-Amz-Signature", valid_595891
  var valid_595892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595892 = validateParameter(valid_595892, JString, required = false,
                                 default = nil)
  if valid_595892 != nil:
    section.add "X-Amz-SignedHeaders", valid_595892
  var valid_595893 = header.getOrDefault("X-Amz-Credential")
  valid_595893 = validateParameter(valid_595893, JString, required = false,
                                 default = nil)
  if valid_595893 != nil:
    section.add "X-Amz-Credential", valid_595893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595895: Call_UpdateTable_595883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_595895.validator(path, query, header, formData, body)
  let scheme = call_595895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595895.url(scheme.get, call_595895.host, call_595895.base,
                         call_595895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595895, url, valid)

proc call*(call_595896: Call_UpdateTable_595883; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_595897 = newJObject()
  if body != nil:
    body_595897 = body
  result = call_595896.call(nil, nil, nil, nil, body_595897)

var updateTable* = Call_UpdateTable_595883(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_595884,
                                        base: "/", url: url_UpdateTable_595885,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_595898 = ref object of OpenApiRestCall_593437
proc url_UpdateTrigger_595900(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTrigger_595899(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a trigger definition.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595901 = header.getOrDefault("X-Amz-Date")
  valid_595901 = validateParameter(valid_595901, JString, required = false,
                                 default = nil)
  if valid_595901 != nil:
    section.add "X-Amz-Date", valid_595901
  var valid_595902 = header.getOrDefault("X-Amz-Security-Token")
  valid_595902 = validateParameter(valid_595902, JString, required = false,
                                 default = nil)
  if valid_595902 != nil:
    section.add "X-Amz-Security-Token", valid_595902
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595903 = header.getOrDefault("X-Amz-Target")
  valid_595903 = validateParameter(valid_595903, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_595903 != nil:
    section.add "X-Amz-Target", valid_595903
  var valid_595904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595904 = validateParameter(valid_595904, JString, required = false,
                                 default = nil)
  if valid_595904 != nil:
    section.add "X-Amz-Content-Sha256", valid_595904
  var valid_595905 = header.getOrDefault("X-Amz-Algorithm")
  valid_595905 = validateParameter(valid_595905, JString, required = false,
                                 default = nil)
  if valid_595905 != nil:
    section.add "X-Amz-Algorithm", valid_595905
  var valid_595906 = header.getOrDefault("X-Amz-Signature")
  valid_595906 = validateParameter(valid_595906, JString, required = false,
                                 default = nil)
  if valid_595906 != nil:
    section.add "X-Amz-Signature", valid_595906
  var valid_595907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595907 = validateParameter(valid_595907, JString, required = false,
                                 default = nil)
  if valid_595907 != nil:
    section.add "X-Amz-SignedHeaders", valid_595907
  var valid_595908 = header.getOrDefault("X-Amz-Credential")
  valid_595908 = validateParameter(valid_595908, JString, required = false,
                                 default = nil)
  if valid_595908 != nil:
    section.add "X-Amz-Credential", valid_595908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595910: Call_UpdateTrigger_595898; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_595910.validator(path, query, header, formData, body)
  let scheme = call_595910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595910.url(scheme.get, call_595910.host, call_595910.base,
                         call_595910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595910, url, valid)

proc call*(call_595911: Call_UpdateTrigger_595898; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_595912 = newJObject()
  if body != nil:
    body_595912 = body
  result = call_595911.call(nil, nil, nil, nil, body_595912)

var updateTrigger* = Call_UpdateTrigger_595898(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_595899, base: "/", url: url_UpdateTrigger_595900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_595913 = ref object of OpenApiRestCall_593437
proc url_UpdateUserDefinedFunction_595915(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateUserDefinedFunction_595914(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing function definition in the Data Catalog.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595916 = header.getOrDefault("X-Amz-Date")
  valid_595916 = validateParameter(valid_595916, JString, required = false,
                                 default = nil)
  if valid_595916 != nil:
    section.add "X-Amz-Date", valid_595916
  var valid_595917 = header.getOrDefault("X-Amz-Security-Token")
  valid_595917 = validateParameter(valid_595917, JString, required = false,
                                 default = nil)
  if valid_595917 != nil:
    section.add "X-Amz-Security-Token", valid_595917
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595918 = header.getOrDefault("X-Amz-Target")
  valid_595918 = validateParameter(valid_595918, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_595918 != nil:
    section.add "X-Amz-Target", valid_595918
  var valid_595919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595919 = validateParameter(valid_595919, JString, required = false,
                                 default = nil)
  if valid_595919 != nil:
    section.add "X-Amz-Content-Sha256", valid_595919
  var valid_595920 = header.getOrDefault("X-Amz-Algorithm")
  valid_595920 = validateParameter(valid_595920, JString, required = false,
                                 default = nil)
  if valid_595920 != nil:
    section.add "X-Amz-Algorithm", valid_595920
  var valid_595921 = header.getOrDefault("X-Amz-Signature")
  valid_595921 = validateParameter(valid_595921, JString, required = false,
                                 default = nil)
  if valid_595921 != nil:
    section.add "X-Amz-Signature", valid_595921
  var valid_595922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595922 = validateParameter(valid_595922, JString, required = false,
                                 default = nil)
  if valid_595922 != nil:
    section.add "X-Amz-SignedHeaders", valid_595922
  var valid_595923 = header.getOrDefault("X-Amz-Credential")
  valid_595923 = validateParameter(valid_595923, JString, required = false,
                                 default = nil)
  if valid_595923 != nil:
    section.add "X-Amz-Credential", valid_595923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595925: Call_UpdateUserDefinedFunction_595913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_595925.validator(path, query, header, formData, body)
  let scheme = call_595925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595925.url(scheme.get, call_595925.host, call_595925.base,
                         call_595925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595925, url, valid)

proc call*(call_595926: Call_UpdateUserDefinedFunction_595913; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_595927 = newJObject()
  if body != nil:
    body_595927 = body
  result = call_595926.call(nil, nil, nil, nil, body_595927)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_595913(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_595914, base: "/",
    url: url_UpdateUserDefinedFunction_595915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_595928 = ref object of OpenApiRestCall_593437
proc url_UpdateWorkflow_595930(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWorkflow_595929(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing workflow.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595931 = header.getOrDefault("X-Amz-Date")
  valid_595931 = validateParameter(valid_595931, JString, required = false,
                                 default = nil)
  if valid_595931 != nil:
    section.add "X-Amz-Date", valid_595931
  var valid_595932 = header.getOrDefault("X-Amz-Security-Token")
  valid_595932 = validateParameter(valid_595932, JString, required = false,
                                 default = nil)
  if valid_595932 != nil:
    section.add "X-Amz-Security-Token", valid_595932
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595933 = header.getOrDefault("X-Amz-Target")
  valid_595933 = validateParameter(valid_595933, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_595933 != nil:
    section.add "X-Amz-Target", valid_595933
  var valid_595934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595934 = validateParameter(valid_595934, JString, required = false,
                                 default = nil)
  if valid_595934 != nil:
    section.add "X-Amz-Content-Sha256", valid_595934
  var valid_595935 = header.getOrDefault("X-Amz-Algorithm")
  valid_595935 = validateParameter(valid_595935, JString, required = false,
                                 default = nil)
  if valid_595935 != nil:
    section.add "X-Amz-Algorithm", valid_595935
  var valid_595936 = header.getOrDefault("X-Amz-Signature")
  valid_595936 = validateParameter(valid_595936, JString, required = false,
                                 default = nil)
  if valid_595936 != nil:
    section.add "X-Amz-Signature", valid_595936
  var valid_595937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595937 = validateParameter(valid_595937, JString, required = false,
                                 default = nil)
  if valid_595937 != nil:
    section.add "X-Amz-SignedHeaders", valid_595937
  var valid_595938 = header.getOrDefault("X-Amz-Credential")
  valid_595938 = validateParameter(valid_595938, JString, required = false,
                                 default = nil)
  if valid_595938 != nil:
    section.add "X-Amz-Credential", valid_595938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595940: Call_UpdateWorkflow_595928; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_595940.validator(path, query, header, formData, body)
  let scheme = call_595940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595940.url(scheme.get, call_595940.host, call_595940.base,
                         call_595940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595940, url, valid)

proc call*(call_595941: Call_UpdateWorkflow_595928; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_595942 = newJObject()
  if body != nil:
    body_595942 = body
  result = call_595941.call(nil, nil, nil, nil, body_595942)

var updateWorkflow* = Call_UpdateWorkflow_595928(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_595929, base: "/", url: url_UpdateWorkflow_595930,
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)

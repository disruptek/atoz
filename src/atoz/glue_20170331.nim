
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_605927 = ref object of OpenApiRestCall_605589
proc url_BatchCreatePartition_605929(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreatePartition_605928(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchCreatePartition"))
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

proc call*(call_606085: Call_BatchCreatePartition_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_BatchCreatePartition_605927; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var batchCreatePartition* = Call_BatchCreatePartition_605927(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_605928, base: "/",
    url: url_BatchCreatePartition_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_606196 = ref object of OpenApiRestCall_605589
proc url_BatchDeleteConnection_606198(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteConnection_606197(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchDeleteConnection"))
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

proc call*(call_606208: Call_BatchDeleteConnection_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_BatchDeleteConnection_606196; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var batchDeleteConnection* = Call_BatchDeleteConnection_606196(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_606197, base: "/",
    url: url_BatchDeleteConnection_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_606211 = ref object of OpenApiRestCall_605589
proc url_BatchDeletePartition_606213(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeletePartition_606212(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchDeletePartition"))
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

proc call*(call_606223: Call_BatchDeletePartition_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_BatchDeletePartition_606211; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var batchDeletePartition* = Call_BatchDeletePartition_606211(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_606212, base: "/",
    url: url_BatchDeletePartition_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_606226 = ref object of OpenApiRestCall_605589
proc url_BatchDeleteTable_606228(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteTable_606227(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchDeleteTable"))
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

proc call*(call_606238: Call_BatchDeleteTable_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_BatchDeleteTable_606226; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var batchDeleteTable* = Call_BatchDeleteTable_606226(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_606227, base: "/",
    url: url_BatchDeleteTable_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_606241 = ref object of OpenApiRestCall_605589
proc url_BatchDeleteTableVersion_606243(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_BatchDeleteTableVersion_606242(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchDeleteTableVersion"))
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

proc call*(call_606253: Call_BatchDeleteTableVersion_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_BatchDeleteTableVersion_606241; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_606241(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_606242, base: "/",
    url: url_BatchDeleteTableVersion_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_606256 = ref object of OpenApiRestCall_605589
proc url_BatchGetCrawlers_606258(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetCrawlers_606257(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchGetCrawlers"))
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

proc call*(call_606268: Call_BatchGetCrawlers_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_BatchGetCrawlers_606256; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var batchGetCrawlers* = Call_BatchGetCrawlers_606256(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_606257, base: "/",
    url: url_BatchGetCrawlers_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_606271 = ref object of OpenApiRestCall_605589
proc url_BatchGetDevEndpoints_606273(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetDevEndpoints_606272(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchGetDevEndpoints"))
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

proc call*(call_606283: Call_BatchGetDevEndpoints_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_BatchGetDevEndpoints_606271; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_606271(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_606272, base: "/",
    url: url_BatchGetDevEndpoints_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_606286 = ref object of OpenApiRestCall_605589
proc url_BatchGetJobs_606288(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetJobs_606287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  valid_606289 = validateParameter(valid_606289, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
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

proc call*(call_606298: Call_BatchGetJobs_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_BatchGetJobs_606286; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var batchGetJobs* = Call_BatchGetJobs_606286(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_606287, base: "/", url: url_BatchGetJobs_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_606301 = ref object of OpenApiRestCall_605589
proc url_BatchGetPartition_606303(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetPartition_606302(path: JsonNode; query: JsonNode;
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
      "AWSGlue.BatchGetPartition"))
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

proc call*(call_606313: Call_BatchGetPartition_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_BatchGetPartition_606301; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var batchGetPartition* = Call_BatchGetPartition_606301(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_606302, base: "/",
    url: url_BatchGetPartition_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_606316 = ref object of OpenApiRestCall_605589
proc url_BatchGetTriggers_606318(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetTriggers_606317(path: JsonNode; query: JsonNode;
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_BatchGetTriggers_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_BatchGetTriggers_606316; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var batchGetTriggers* = Call_BatchGetTriggers_606316(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_606317, base: "/",
    url: url_BatchGetTriggers_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_606331 = ref object of OpenApiRestCall_605589
proc url_BatchGetWorkflows_606333(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetWorkflows_606332(path: JsonNode; query: JsonNode;
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_BatchGetWorkflows_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_BatchGetWorkflows_606331; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var batchGetWorkflows* = Call_BatchGetWorkflows_606331(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_606332, base: "/",
    url: url_BatchGetWorkflows_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_606346 = ref object of OpenApiRestCall_605589
proc url_BatchStopJobRun_606348(protocol: Scheme; host: string; base: string;
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

proc validate_BatchStopJobRun_606347(path: JsonNode; query: JsonNode;
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_BatchStopJobRun_606346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_BatchStopJobRun_606346; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var batchStopJobRun* = Call_BatchStopJobRun_606346(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_606347, base: "/", url: url_BatchStopJobRun_606348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_606361 = ref object of OpenApiRestCall_605589
proc url_CancelMLTaskRun_606363(protocol: Scheme; host: string; base: string;
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

proc validate_CancelMLTaskRun_606362(path: JsonNode; query: JsonNode;
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
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_CancelMLTaskRun_606361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_CancelMLTaskRun_606361; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var cancelMLTaskRun* = Call_CancelMLTaskRun_606361(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_606362, base: "/", url: url_CancelMLTaskRun_606363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_606376 = ref object of OpenApiRestCall_605589
proc url_CreateClassifier_606378(protocol: Scheme; host: string; base: string;
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

proc validate_CreateClassifier_606377(path: JsonNode; query: JsonNode;
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_CreateClassifier_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_CreateClassifier_606376; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var createClassifier* = Call_CreateClassifier_606376(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_606377, base: "/",
    url: url_CreateClassifier_606378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_606391 = ref object of OpenApiRestCall_605589
proc url_CreateConnection_606393(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConnection_606392(path: JsonNode; query: JsonNode;
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
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_CreateConnection_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_CreateConnection_606391; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var createConnection* = Call_CreateConnection_606391(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_606392, base: "/",
    url: url_CreateConnection_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_606406 = ref object of OpenApiRestCall_605589
proc url_CreateCrawler_606408(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCrawler_606407(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_CreateCrawler_606406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_CreateCrawler_606406; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var createCrawler* = Call_CreateCrawler_606406(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_606407, base: "/", url: url_CreateCrawler_606408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_606421 = ref object of OpenApiRestCall_605589
proc url_CreateDatabase_606423(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatabase_606422(path: JsonNode; query: JsonNode;
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
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_CreateDatabase_606421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_CreateDatabase_606421; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var createDatabase* = Call_CreateDatabase_606421(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_606422, base: "/", url: url_CreateDatabase_606423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_606436 = ref object of OpenApiRestCall_605589
proc url_CreateDevEndpoint_606438(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevEndpoint_606437(path: JsonNode; query: JsonNode;
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
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_CreateDevEndpoint_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_CreateDevEndpoint_606436; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var createDevEndpoint* = Call_CreateDevEndpoint_606436(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_606437, base: "/",
    url: url_CreateDevEndpoint_606438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_606451 = ref object of OpenApiRestCall_605589
proc url_CreateJob_606453(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateJob_606452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_CreateJob_606451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_CreateJob_606451; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var createJob* = Call_CreateJob_606451(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_606452,
                                    base: "/", url: url_CreateJob_606453,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_606466 = ref object of OpenApiRestCall_605589
proc url_CreateMLTransform_606468(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMLTransform_606467(path: JsonNode; query: JsonNode;
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
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_CreateMLTransform_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_CreateMLTransform_606466; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var createMLTransform* = Call_CreateMLTransform_606466(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_606467, base: "/",
    url: url_CreateMLTransform_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_606481 = ref object of OpenApiRestCall_605589
proc url_CreatePartition_606483(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePartition_606482(path: JsonNode; query: JsonNode;
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
  var valid_606484 = header.getOrDefault("X-Amz-Target")
  valid_606484 = validateParameter(valid_606484, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_606484 != nil:
    section.add "X-Amz-Target", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_CreatePartition_606481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_CreatePartition_606481; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_606495 = newJObject()
  if body != nil:
    body_606495 = body
  result = call_606494.call(nil, nil, nil, nil, body_606495)

var createPartition* = Call_CreatePartition_606481(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_606482, base: "/", url: url_CreatePartition_606483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_606496 = ref object of OpenApiRestCall_605589
proc url_CreateScript_606498(protocol: Scheme; host: string; base: string;
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

proc validate_CreateScript_606497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606499 = header.getOrDefault("X-Amz-Target")
  valid_606499 = validateParameter(valid_606499, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_606499 != nil:
    section.add "X-Amz-Target", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_CreateScript_606496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_CreateScript_606496; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var createScript* = Call_CreateScript_606496(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_606497, base: "/", url: url_CreateScript_606498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_606511 = ref object of OpenApiRestCall_605589
proc url_CreateSecurityConfiguration_606513(protocol: Scheme; host: string;
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

proc validate_CreateSecurityConfiguration_606512(path: JsonNode; query: JsonNode;
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
  var valid_606514 = header.getOrDefault("X-Amz-Target")
  valid_606514 = validateParameter(valid_606514, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_606514 != nil:
    section.add "X-Amz-Target", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_CreateSecurityConfiguration_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_CreateSecurityConfiguration_606511; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_606525 = newJObject()
  if body != nil:
    body_606525 = body
  result = call_606524.call(nil, nil, nil, nil, body_606525)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_606511(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_606512, base: "/",
    url: url_CreateSecurityConfiguration_606513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_606526 = ref object of OpenApiRestCall_605589
proc url_CreateTable_606528(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTable_606527(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606529 = header.getOrDefault("X-Amz-Target")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_606529 != nil:
    section.add "X-Amz-Target", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_CreateTable_606526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_CreateTable_606526; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var createTable* = Call_CreateTable_606526(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_606527,
                                        base: "/", url: url_CreateTable_606528,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_606541 = ref object of OpenApiRestCall_605589
proc url_CreateTrigger_606543(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrigger_606542(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_CreateTrigger_606541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_CreateTrigger_606541; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_606555 = newJObject()
  if body != nil:
    body_606555 = body
  result = call_606554.call(nil, nil, nil, nil, body_606555)

var createTrigger* = Call_CreateTrigger_606541(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_606542, base: "/", url: url_CreateTrigger_606543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_606556 = ref object of OpenApiRestCall_605589
proc url_CreateUserDefinedFunction_606558(protocol: Scheme; host: string;
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

proc validate_CreateUserDefinedFunction_606557(path: JsonNode; query: JsonNode;
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
  var valid_606559 = header.getOrDefault("X-Amz-Target")
  valid_606559 = validateParameter(valid_606559, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_606559 != nil:
    section.add "X-Amz-Target", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_CreateUserDefinedFunction_606556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_CreateUserDefinedFunction_606556; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_606570 = newJObject()
  if body != nil:
    body_606570 = body
  result = call_606569.call(nil, nil, nil, nil, body_606570)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_606556(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_606557, base: "/",
    url: url_CreateUserDefinedFunction_606558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_606571 = ref object of OpenApiRestCall_605589
proc url_CreateWorkflow_606573(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkflow_606572(path: JsonNode; query: JsonNode;
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
  var valid_606574 = header.getOrDefault("X-Amz-Target")
  valid_606574 = validateParameter(valid_606574, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_606574 != nil:
    section.add "X-Amz-Target", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Signature")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Signature", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Content-Sha256", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Date")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Date", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Credential")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Credential", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Security-Token")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Security-Token", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Algorithm")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Algorithm", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-SignedHeaders", valid_606581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606583: Call_CreateWorkflow_606571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_606583.validator(path, query, header, formData, body)
  let scheme = call_606583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606583.url(scheme.get, call_606583.host, call_606583.base,
                         call_606583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606583, url, valid)

proc call*(call_606584: Call_CreateWorkflow_606571; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_606585 = newJObject()
  if body != nil:
    body_606585 = body
  result = call_606584.call(nil, nil, nil, nil, body_606585)

var createWorkflow* = Call_CreateWorkflow_606571(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_606572, base: "/", url: url_CreateWorkflow_606573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_606586 = ref object of OpenApiRestCall_605589
proc url_DeleteClassifier_606588(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClassifier_606587(path: JsonNode; query: JsonNode;
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
  var valid_606589 = header.getOrDefault("X-Amz-Target")
  valid_606589 = validateParameter(valid_606589, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_606589 != nil:
    section.add "X-Amz-Target", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Signature")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Signature", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Content-Sha256", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Date")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Date", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Credential")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Credential", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Security-Token")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Security-Token", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Algorithm")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Algorithm", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-SignedHeaders", valid_606596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_DeleteClassifier_606586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_DeleteClassifier_606586; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_606600 = newJObject()
  if body != nil:
    body_606600 = body
  result = call_606599.call(nil, nil, nil, nil, body_606600)

var deleteClassifier* = Call_DeleteClassifier_606586(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_606587, base: "/",
    url: url_DeleteClassifier_606588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_606601 = ref object of OpenApiRestCall_605589
proc url_DeleteConnection_606603(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConnection_606602(path: JsonNode; query: JsonNode;
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
  var valid_606604 = header.getOrDefault("X-Amz-Target")
  valid_606604 = validateParameter(valid_606604, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_606604 != nil:
    section.add "X-Amz-Target", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Signature")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Signature", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Content-Sha256", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Date")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Date", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Credential")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Credential", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Security-Token")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Security-Token", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Algorithm")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Algorithm", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-SignedHeaders", valid_606611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606613: Call_DeleteConnection_606601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_606613.validator(path, query, header, formData, body)
  let scheme = call_606613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606613.url(scheme.get, call_606613.host, call_606613.base,
                         call_606613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606613, url, valid)

proc call*(call_606614: Call_DeleteConnection_606601; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_606615 = newJObject()
  if body != nil:
    body_606615 = body
  result = call_606614.call(nil, nil, nil, nil, body_606615)

var deleteConnection* = Call_DeleteConnection_606601(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_606602, base: "/",
    url: url_DeleteConnection_606603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_606616 = ref object of OpenApiRestCall_605589
proc url_DeleteCrawler_606618(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCrawler_606617(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606619 = header.getOrDefault("X-Amz-Target")
  valid_606619 = validateParameter(valid_606619, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_606619 != nil:
    section.add "X-Amz-Target", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Signature")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Signature", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Content-Sha256", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Date")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Date", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Credential")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Credential", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606628: Call_DeleteCrawler_606616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_606628.validator(path, query, header, formData, body)
  let scheme = call_606628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606628.url(scheme.get, call_606628.host, call_606628.base,
                         call_606628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606628, url, valid)

proc call*(call_606629: Call_DeleteCrawler_606616; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_606630 = newJObject()
  if body != nil:
    body_606630 = body
  result = call_606629.call(nil, nil, nil, nil, body_606630)

var deleteCrawler* = Call_DeleteCrawler_606616(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_606617, base: "/", url: url_DeleteCrawler_606618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_606631 = ref object of OpenApiRestCall_605589
proc url_DeleteDatabase_606633(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatabase_606632(path: JsonNode; query: JsonNode;
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
  var valid_606634 = header.getOrDefault("X-Amz-Target")
  valid_606634 = validateParameter(valid_606634, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_606634 != nil:
    section.add "X-Amz-Target", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Signature")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Signature", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Content-Sha256", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Date")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Date", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Credential")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Credential", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Security-Token")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Security-Token", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Algorithm")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Algorithm", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-SignedHeaders", valid_606641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_DeleteDatabase_606631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_DeleteDatabase_606631; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_606645 = newJObject()
  if body != nil:
    body_606645 = body
  result = call_606644.call(nil, nil, nil, nil, body_606645)

var deleteDatabase* = Call_DeleteDatabase_606631(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_606632, base: "/", url: url_DeleteDatabase_606633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_606646 = ref object of OpenApiRestCall_605589
proc url_DeleteDevEndpoint_606648(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevEndpoint_606647(path: JsonNode; query: JsonNode;
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
  var valid_606649 = header.getOrDefault("X-Amz-Target")
  valid_606649 = validateParameter(valid_606649, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_606649 != nil:
    section.add "X-Amz-Target", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Signature")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Signature", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Content-Sha256", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Date")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Date", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Credential")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Credential", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Security-Token")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Security-Token", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Algorithm")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Algorithm", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-SignedHeaders", valid_606656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606658: Call_DeleteDevEndpoint_606646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_606658.validator(path, query, header, formData, body)
  let scheme = call_606658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606658.url(scheme.get, call_606658.host, call_606658.base,
                         call_606658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606658, url, valid)

proc call*(call_606659: Call_DeleteDevEndpoint_606646; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_606660 = newJObject()
  if body != nil:
    body_606660 = body
  result = call_606659.call(nil, nil, nil, nil, body_606660)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_606646(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_606647, base: "/",
    url: url_DeleteDevEndpoint_606648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_606661 = ref object of OpenApiRestCall_605589
proc url_DeleteJob_606663(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_606662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606664 = header.getOrDefault("X-Amz-Target")
  valid_606664 = validateParameter(valid_606664, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_606664 != nil:
    section.add "X-Amz-Target", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Signature")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Signature", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Content-Sha256", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Date")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Date", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Credential")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Credential", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Security-Token")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Security-Token", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Algorithm")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Algorithm", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-SignedHeaders", valid_606671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606673: Call_DeleteJob_606661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_606673.validator(path, query, header, formData, body)
  let scheme = call_606673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606673.url(scheme.get, call_606673.host, call_606673.base,
                         call_606673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606673, url, valid)

proc call*(call_606674: Call_DeleteJob_606661; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_606675 = newJObject()
  if body != nil:
    body_606675 = body
  result = call_606674.call(nil, nil, nil, nil, body_606675)

var deleteJob* = Call_DeleteJob_606661(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_606662,
                                    base: "/", url: url_DeleteJob_606663,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_606676 = ref object of OpenApiRestCall_605589
proc url_DeleteMLTransform_606678(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMLTransform_606677(path: JsonNode; query: JsonNode;
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
  var valid_606679 = header.getOrDefault("X-Amz-Target")
  valid_606679 = validateParameter(valid_606679, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_606679 != nil:
    section.add "X-Amz-Target", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Signature")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Signature", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Content-Sha256", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Date")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Date", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Credential")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Credential", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Security-Token")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Security-Token", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Algorithm")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Algorithm", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-SignedHeaders", valid_606686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606688: Call_DeleteMLTransform_606676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_606688.validator(path, query, header, formData, body)
  let scheme = call_606688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606688.url(scheme.get, call_606688.host, call_606688.base,
                         call_606688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606688, url, valid)

proc call*(call_606689: Call_DeleteMLTransform_606676; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_606690 = newJObject()
  if body != nil:
    body_606690 = body
  result = call_606689.call(nil, nil, nil, nil, body_606690)

var deleteMLTransform* = Call_DeleteMLTransform_606676(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_606677, base: "/",
    url: url_DeleteMLTransform_606678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_606691 = ref object of OpenApiRestCall_605589
proc url_DeletePartition_606693(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePartition_606692(path: JsonNode; query: JsonNode;
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
  var valid_606694 = header.getOrDefault("X-Amz-Target")
  valid_606694 = validateParameter(valid_606694, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_606694 != nil:
    section.add "X-Amz-Target", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Signature")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Signature", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Content-Sha256", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Date")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Date", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Credential")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Credential", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Security-Token")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Security-Token", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Algorithm")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Algorithm", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-SignedHeaders", valid_606701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606703: Call_DeletePartition_606691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_606703.validator(path, query, header, formData, body)
  let scheme = call_606703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606703.url(scheme.get, call_606703.host, call_606703.base,
                         call_606703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606703, url, valid)

proc call*(call_606704: Call_DeletePartition_606691; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_606705 = newJObject()
  if body != nil:
    body_606705 = body
  result = call_606704.call(nil, nil, nil, nil, body_606705)

var deletePartition* = Call_DeletePartition_606691(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_606692, base: "/", url: url_DeletePartition_606693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_606706 = ref object of OpenApiRestCall_605589
proc url_DeleteResourcePolicy_606708(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourcePolicy_606707(path: JsonNode; query: JsonNode;
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
  var valid_606709 = header.getOrDefault("X-Amz-Target")
  valid_606709 = validateParameter(valid_606709, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_606709 != nil:
    section.add "X-Amz-Target", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Signature")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Signature", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Content-Sha256", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Date")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Date", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Credential")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Credential", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Security-Token")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Security-Token", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Algorithm")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Algorithm", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-SignedHeaders", valid_606716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606718: Call_DeleteResourcePolicy_606706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_606718.validator(path, query, header, formData, body)
  let scheme = call_606718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606718.url(scheme.get, call_606718.host, call_606718.base,
                         call_606718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606718, url, valid)

proc call*(call_606719: Call_DeleteResourcePolicy_606706; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_606720 = newJObject()
  if body != nil:
    body_606720 = body
  result = call_606719.call(nil, nil, nil, nil, body_606720)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_606706(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_606707, base: "/",
    url: url_DeleteResourcePolicy_606708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_606721 = ref object of OpenApiRestCall_605589
proc url_DeleteSecurityConfiguration_606723(protocol: Scheme; host: string;
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

proc validate_DeleteSecurityConfiguration_606722(path: JsonNode; query: JsonNode;
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
  var valid_606724 = header.getOrDefault("X-Amz-Target")
  valid_606724 = validateParameter(valid_606724, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_606724 != nil:
    section.add "X-Amz-Target", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Signature")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Signature", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Content-Sha256", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Date")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Date", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Credential")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Credential", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Security-Token")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Security-Token", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Algorithm")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Algorithm", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-SignedHeaders", valid_606731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606733: Call_DeleteSecurityConfiguration_606721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_606733.validator(path, query, header, formData, body)
  let scheme = call_606733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606733.url(scheme.get, call_606733.host, call_606733.base,
                         call_606733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606733, url, valid)

proc call*(call_606734: Call_DeleteSecurityConfiguration_606721; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_606735 = newJObject()
  if body != nil:
    body_606735 = body
  result = call_606734.call(nil, nil, nil, nil, body_606735)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_606721(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_606722, base: "/",
    url: url_DeleteSecurityConfiguration_606723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_606736 = ref object of OpenApiRestCall_605589
proc url_DeleteTable_606738(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTable_606737(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606739 = header.getOrDefault("X-Amz-Target")
  valid_606739 = validateParameter(valid_606739, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_606739 != nil:
    section.add "X-Amz-Target", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Signature")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Signature", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Content-Sha256", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Date")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Date", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Credential")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Credential", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Security-Token")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Security-Token", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Algorithm")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Algorithm", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-SignedHeaders", valid_606746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_DeleteTable_606736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_DeleteTable_606736; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_606750 = newJObject()
  if body != nil:
    body_606750 = body
  result = call_606749.call(nil, nil, nil, nil, body_606750)

var deleteTable* = Call_DeleteTable_606736(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_606737,
                                        base: "/", url: url_DeleteTable_606738,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_606751 = ref object of OpenApiRestCall_605589
proc url_DeleteTableVersion_606753(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTableVersion_606752(path: JsonNode; query: JsonNode;
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
  var valid_606754 = header.getOrDefault("X-Amz-Target")
  valid_606754 = validateParameter(valid_606754, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_606754 != nil:
    section.add "X-Amz-Target", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Signature")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Signature", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Content-Sha256", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Date")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Date", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Credential")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Credential", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Security-Token")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Security-Token", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Algorithm")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Algorithm", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-SignedHeaders", valid_606761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606763: Call_DeleteTableVersion_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_606763.validator(path, query, header, formData, body)
  let scheme = call_606763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606763.url(scheme.get, call_606763.host, call_606763.base,
                         call_606763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606763, url, valid)

proc call*(call_606764: Call_DeleteTableVersion_606751; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_606765 = newJObject()
  if body != nil:
    body_606765 = body
  result = call_606764.call(nil, nil, nil, nil, body_606765)

var deleteTableVersion* = Call_DeleteTableVersion_606751(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_606752, base: "/",
    url: url_DeleteTableVersion_606753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_606766 = ref object of OpenApiRestCall_605589
proc url_DeleteTrigger_606768(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrigger_606767(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606769 = header.getOrDefault("X-Amz-Target")
  valid_606769 = validateParameter(valid_606769, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_606769 != nil:
    section.add "X-Amz-Target", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Signature")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Signature", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Content-Sha256", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Date")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Date", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Credential")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Credential", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Security-Token")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Security-Token", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Algorithm")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Algorithm", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-SignedHeaders", valid_606776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606778: Call_DeleteTrigger_606766; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_606778.validator(path, query, header, formData, body)
  let scheme = call_606778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606778.url(scheme.get, call_606778.host, call_606778.base,
                         call_606778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606778, url, valid)

proc call*(call_606779: Call_DeleteTrigger_606766; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_606780 = newJObject()
  if body != nil:
    body_606780 = body
  result = call_606779.call(nil, nil, nil, nil, body_606780)

var deleteTrigger* = Call_DeleteTrigger_606766(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_606767, base: "/", url: url_DeleteTrigger_606768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_606781 = ref object of OpenApiRestCall_605589
proc url_DeleteUserDefinedFunction_606783(protocol: Scheme; host: string;
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

proc validate_DeleteUserDefinedFunction_606782(path: JsonNode; query: JsonNode;
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
  var valid_606784 = header.getOrDefault("X-Amz-Target")
  valid_606784 = validateParameter(valid_606784, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_606784 != nil:
    section.add "X-Amz-Target", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Signature")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Signature", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Content-Sha256", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Date")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Date", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Credential")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Credential", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Security-Token")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Security-Token", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Algorithm")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Algorithm", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-SignedHeaders", valid_606791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606793: Call_DeleteUserDefinedFunction_606781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_606793.validator(path, query, header, formData, body)
  let scheme = call_606793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606793.url(scheme.get, call_606793.host, call_606793.base,
                         call_606793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606793, url, valid)

proc call*(call_606794: Call_DeleteUserDefinedFunction_606781; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_606795 = newJObject()
  if body != nil:
    body_606795 = body
  result = call_606794.call(nil, nil, nil, nil, body_606795)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_606781(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_606782, base: "/",
    url: url_DeleteUserDefinedFunction_606783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_606796 = ref object of OpenApiRestCall_605589
proc url_DeleteWorkflow_606798(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkflow_606797(path: JsonNode; query: JsonNode;
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
  var valid_606799 = header.getOrDefault("X-Amz-Target")
  valid_606799 = validateParameter(valid_606799, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_606799 != nil:
    section.add "X-Amz-Target", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Signature")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Signature", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Content-Sha256", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Date")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Date", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Credential")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Credential", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-Security-Token")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-Security-Token", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-Algorithm")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Algorithm", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-SignedHeaders", valid_606806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606808: Call_DeleteWorkflow_606796; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_606808.validator(path, query, header, formData, body)
  let scheme = call_606808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606808.url(scheme.get, call_606808.host, call_606808.base,
                         call_606808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606808, url, valid)

proc call*(call_606809: Call_DeleteWorkflow_606796; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_606810 = newJObject()
  if body != nil:
    body_606810 = body
  result = call_606809.call(nil, nil, nil, nil, body_606810)

var deleteWorkflow* = Call_DeleteWorkflow_606796(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_606797, base: "/", url: url_DeleteWorkflow_606798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_606811 = ref object of OpenApiRestCall_605589
proc url_GetCatalogImportStatus_606813(protocol: Scheme; host: string; base: string;
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

proc validate_GetCatalogImportStatus_606812(path: JsonNode; query: JsonNode;
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
  var valid_606814 = header.getOrDefault("X-Amz-Target")
  valid_606814 = validateParameter(valid_606814, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_606814 != nil:
    section.add "X-Amz-Target", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Signature")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Signature", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Content-Sha256", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Date")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Date", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Credential")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Credential", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Security-Token")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Security-Token", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Algorithm")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Algorithm", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-SignedHeaders", valid_606821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606823: Call_GetCatalogImportStatus_606811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_606823.validator(path, query, header, formData, body)
  let scheme = call_606823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606823.url(scheme.get, call_606823.host, call_606823.base,
                         call_606823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606823, url, valid)

proc call*(call_606824: Call_GetCatalogImportStatus_606811; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_606825 = newJObject()
  if body != nil:
    body_606825 = body
  result = call_606824.call(nil, nil, nil, nil, body_606825)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_606811(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_606812, base: "/",
    url: url_GetCatalogImportStatus_606813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_606826 = ref object of OpenApiRestCall_605589
proc url_GetClassifier_606828(protocol: Scheme; host: string; base: string;
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

proc validate_GetClassifier_606827(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606829 = header.getOrDefault("X-Amz-Target")
  valid_606829 = validateParameter(valid_606829, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_606829 != nil:
    section.add "X-Amz-Target", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Signature")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Signature", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Content-Sha256", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Date")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Date", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Credential")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Credential", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Security-Token")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Security-Token", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-Algorithm")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-Algorithm", valid_606835
  var valid_606836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-SignedHeaders", valid_606836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606838: Call_GetClassifier_606826; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_606838.validator(path, query, header, formData, body)
  let scheme = call_606838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606838.url(scheme.get, call_606838.host, call_606838.base,
                         call_606838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606838, url, valid)

proc call*(call_606839: Call_GetClassifier_606826; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_606840 = newJObject()
  if body != nil:
    body_606840 = body
  result = call_606839.call(nil, nil, nil, nil, body_606840)

var getClassifier* = Call_GetClassifier_606826(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_606827, base: "/", url: url_GetClassifier_606828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_606841 = ref object of OpenApiRestCall_605589
proc url_GetClassifiers_606843(protocol: Scheme; host: string; base: string;
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

proc validate_GetClassifiers_606842(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all classifier objects in the Data Catalog.
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
  var valid_606844 = query.getOrDefault("MaxResults")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "MaxResults", valid_606844
  var valid_606845 = query.getOrDefault("NextToken")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "NextToken", valid_606845
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
  var valid_606846 = header.getOrDefault("X-Amz-Target")
  valid_606846 = validateParameter(valid_606846, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_606846 != nil:
    section.add "X-Amz-Target", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Signature")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Signature", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Content-Sha256", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Date")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Date", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Credential")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Credential", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-Security-Token")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-Security-Token", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-Algorithm")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Algorithm", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-SignedHeaders", valid_606853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606855: Call_GetClassifiers_606841; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_606855.validator(path, query, header, formData, body)
  let scheme = call_606855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606855.url(scheme.get, call_606855.host, call_606855.base,
                         call_606855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606855, url, valid)

proc call*(call_606856: Call_GetClassifiers_606841; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606857 = newJObject()
  var body_606858 = newJObject()
  add(query_606857, "MaxResults", newJString(MaxResults))
  add(query_606857, "NextToken", newJString(NextToken))
  if body != nil:
    body_606858 = body
  result = call_606856.call(nil, query_606857, nil, nil, body_606858)

var getClassifiers* = Call_GetClassifiers_606841(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_606842, base: "/", url: url_GetClassifiers_606843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_606860 = ref object of OpenApiRestCall_605589
proc url_GetConnection_606862(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnection_606861(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606863 = header.getOrDefault("X-Amz-Target")
  valid_606863 = validateParameter(valid_606863, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_606863 != nil:
    section.add "X-Amz-Target", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Signature")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Signature", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Content-Sha256", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-Date")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-Date", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Credential")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Credential", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Security-Token")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Security-Token", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Algorithm")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Algorithm", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-SignedHeaders", valid_606870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606872: Call_GetConnection_606860; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_606872.validator(path, query, header, formData, body)
  let scheme = call_606872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606872.url(scheme.get, call_606872.host, call_606872.base,
                         call_606872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606872, url, valid)

proc call*(call_606873: Call_GetConnection_606860; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_606874 = newJObject()
  if body != nil:
    body_606874 = body
  result = call_606873.call(nil, nil, nil, nil, body_606874)

var getConnection* = Call_GetConnection_606860(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_606861, base: "/", url: url_GetConnection_606862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_606875 = ref object of OpenApiRestCall_605589
proc url_GetConnections_606877(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnections_606876(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of connection definitions from the Data Catalog.
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
  var valid_606878 = query.getOrDefault("MaxResults")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "MaxResults", valid_606878
  var valid_606879 = query.getOrDefault("NextToken")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "NextToken", valid_606879
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
  var valid_606880 = header.getOrDefault("X-Amz-Target")
  valid_606880 = validateParameter(valid_606880, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_606880 != nil:
    section.add "X-Amz-Target", valid_606880
  var valid_606881 = header.getOrDefault("X-Amz-Signature")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Signature", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Content-Sha256", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Date")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Date", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Credential")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Credential", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Security-Token")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Security-Token", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Algorithm")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Algorithm", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-SignedHeaders", valid_606887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606889: Call_GetConnections_606875; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_606889.validator(path, query, header, formData, body)
  let scheme = call_606889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606889.url(scheme.get, call_606889.host, call_606889.base,
                         call_606889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606889, url, valid)

proc call*(call_606890: Call_GetConnections_606875; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606891 = newJObject()
  var body_606892 = newJObject()
  add(query_606891, "MaxResults", newJString(MaxResults))
  add(query_606891, "NextToken", newJString(NextToken))
  if body != nil:
    body_606892 = body
  result = call_606890.call(nil, query_606891, nil, nil, body_606892)

var getConnections* = Call_GetConnections_606875(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_606876, base: "/", url: url_GetConnections_606877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_606893 = ref object of OpenApiRestCall_605589
proc url_GetCrawler_606895(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetCrawler_606894(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606896 = header.getOrDefault("X-Amz-Target")
  valid_606896 = validateParameter(valid_606896, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_606896 != nil:
    section.add "X-Amz-Target", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Signature")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Signature", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Content-Sha256", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Date")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Date", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Credential")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Credential", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Security-Token")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Security-Token", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Algorithm")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Algorithm", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-SignedHeaders", valid_606903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606905: Call_GetCrawler_606893; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_606905.validator(path, query, header, formData, body)
  let scheme = call_606905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606905.url(scheme.get, call_606905.host, call_606905.base,
                         call_606905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606905, url, valid)

proc call*(call_606906: Call_GetCrawler_606893; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_606907 = newJObject()
  if body != nil:
    body_606907 = body
  result = call_606906.call(nil, nil, nil, nil, body_606907)

var getCrawler* = Call_GetCrawler_606893(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_606894,
                                      base: "/", url: url_GetCrawler_606895,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_606908 = ref object of OpenApiRestCall_605589
proc url_GetCrawlerMetrics_606910(protocol: Scheme; host: string; base: string;
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

proc validate_GetCrawlerMetrics_606909(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves metrics about specified crawlers.
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
  var valid_606911 = query.getOrDefault("MaxResults")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "MaxResults", valid_606911
  var valid_606912 = query.getOrDefault("NextToken")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "NextToken", valid_606912
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
  var valid_606913 = header.getOrDefault("X-Amz-Target")
  valid_606913 = validateParameter(valid_606913, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_606913 != nil:
    section.add "X-Amz-Target", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Signature")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Signature", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Content-Sha256", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Date")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Date", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Credential")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Credential", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Security-Token")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Security-Token", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Algorithm")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Algorithm", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-SignedHeaders", valid_606920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606922: Call_GetCrawlerMetrics_606908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_606922.validator(path, query, header, formData, body)
  let scheme = call_606922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606922.url(scheme.get, call_606922.host, call_606922.base,
                         call_606922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606922, url, valid)

proc call*(call_606923: Call_GetCrawlerMetrics_606908; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606924 = newJObject()
  var body_606925 = newJObject()
  add(query_606924, "MaxResults", newJString(MaxResults))
  add(query_606924, "NextToken", newJString(NextToken))
  if body != nil:
    body_606925 = body
  result = call_606923.call(nil, query_606924, nil, nil, body_606925)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_606908(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_606909, base: "/",
    url: url_GetCrawlerMetrics_606910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_606926 = ref object of OpenApiRestCall_605589
proc url_GetCrawlers_606928(protocol: Scheme; host: string; base: string;
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

proc validate_GetCrawlers_606927(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all crawlers defined in the customer account.
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
  var valid_606929 = query.getOrDefault("MaxResults")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "MaxResults", valid_606929
  var valid_606930 = query.getOrDefault("NextToken")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "NextToken", valid_606930
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
  var valid_606931 = header.getOrDefault("X-Amz-Target")
  valid_606931 = validateParameter(valid_606931, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_606931 != nil:
    section.add "X-Amz-Target", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Signature")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Signature", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Content-Sha256", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Date")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Date", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Credential")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Credential", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Security-Token")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Security-Token", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Algorithm")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Algorithm", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-SignedHeaders", valid_606938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606940: Call_GetCrawlers_606926; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_606940.validator(path, query, header, formData, body)
  let scheme = call_606940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606940.url(scheme.get, call_606940.host, call_606940.base,
                         call_606940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606940, url, valid)

proc call*(call_606941: Call_GetCrawlers_606926; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606942 = newJObject()
  var body_606943 = newJObject()
  add(query_606942, "MaxResults", newJString(MaxResults))
  add(query_606942, "NextToken", newJString(NextToken))
  if body != nil:
    body_606943 = body
  result = call_606941.call(nil, query_606942, nil, nil, body_606943)

var getCrawlers* = Call_GetCrawlers_606926(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_606927,
                                        base: "/", url: url_GetCrawlers_606928,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_606944 = ref object of OpenApiRestCall_605589
proc url_GetDataCatalogEncryptionSettings_606946(protocol: Scheme; host: string;
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

proc validate_GetDataCatalogEncryptionSettings_606945(path: JsonNode;
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
  var valid_606947 = header.getOrDefault("X-Amz-Target")
  valid_606947 = validateParameter(valid_606947, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_606947 != nil:
    section.add "X-Amz-Target", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Signature")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Signature", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Content-Sha256", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Date")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Date", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Credential")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Credential", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Security-Token")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Security-Token", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-Algorithm")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Algorithm", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-SignedHeaders", valid_606954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606956: Call_GetDataCatalogEncryptionSettings_606944;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_606956.validator(path, query, header, formData, body)
  let scheme = call_606956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606956.url(scheme.get, call_606956.host, call_606956.base,
                         call_606956.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606956, url, valid)

proc call*(call_606957: Call_GetDataCatalogEncryptionSettings_606944;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_606958 = newJObject()
  if body != nil:
    body_606958 = body
  result = call_606957.call(nil, nil, nil, nil, body_606958)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_606944(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_606945, base: "/",
    url: url_GetDataCatalogEncryptionSettings_606946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_606959 = ref object of OpenApiRestCall_605589
proc url_GetDatabase_606961(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatabase_606960(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606962 = header.getOrDefault("X-Amz-Target")
  valid_606962 = validateParameter(valid_606962, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_606962 != nil:
    section.add "X-Amz-Target", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Signature")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Signature", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Content-Sha256", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-Date")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Date", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-Credential")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-Credential", valid_606966
  var valid_606967 = header.getOrDefault("X-Amz-Security-Token")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "X-Amz-Security-Token", valid_606967
  var valid_606968 = header.getOrDefault("X-Amz-Algorithm")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "X-Amz-Algorithm", valid_606968
  var valid_606969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-SignedHeaders", valid_606969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606971: Call_GetDatabase_606959; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_606971.validator(path, query, header, formData, body)
  let scheme = call_606971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606971.url(scheme.get, call_606971.host, call_606971.base,
                         call_606971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606971, url, valid)

proc call*(call_606972: Call_GetDatabase_606959; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_606973 = newJObject()
  if body != nil:
    body_606973 = body
  result = call_606972.call(nil, nil, nil, nil, body_606973)

var getDatabase* = Call_GetDatabase_606959(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_606960,
                                        base: "/", url: url_GetDatabase_606961,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_606974 = ref object of OpenApiRestCall_605589
proc url_GetDatabases_606976(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatabases_606975(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all databases defined in a given Data Catalog.
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
  var valid_606977 = query.getOrDefault("MaxResults")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "MaxResults", valid_606977
  var valid_606978 = query.getOrDefault("NextToken")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "NextToken", valid_606978
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
  var valid_606979 = header.getOrDefault("X-Amz-Target")
  valid_606979 = validateParameter(valid_606979, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_606979 != nil:
    section.add "X-Amz-Target", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-Signature")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Signature", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-Content-Sha256", valid_606981
  var valid_606982 = header.getOrDefault("X-Amz-Date")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Date", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Credential")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Credential", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Security-Token")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Security-Token", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Algorithm")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Algorithm", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-SignedHeaders", valid_606986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606988: Call_GetDatabases_606974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_606988.validator(path, query, header, formData, body)
  let scheme = call_606988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606988.url(scheme.get, call_606988.host, call_606988.base,
                         call_606988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606988, url, valid)

proc call*(call_606989: Call_GetDatabases_606974; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606990 = newJObject()
  var body_606991 = newJObject()
  add(query_606990, "MaxResults", newJString(MaxResults))
  add(query_606990, "NextToken", newJString(NextToken))
  if body != nil:
    body_606991 = body
  result = call_606989.call(nil, query_606990, nil, nil, body_606991)

var getDatabases* = Call_GetDatabases_606974(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_606975, base: "/", url: url_GetDatabases_606976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_606992 = ref object of OpenApiRestCall_605589
proc url_GetDataflowGraph_606994(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataflowGraph_606993(path: JsonNode; query: JsonNode;
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
  var valid_606995 = header.getOrDefault("X-Amz-Target")
  valid_606995 = validateParameter(valid_606995, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_606995 != nil:
    section.add "X-Amz-Target", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Signature")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Signature", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Content-Sha256", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Date")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Date", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Credential")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Credential", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Security-Token")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Security-Token", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-Algorithm")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-Algorithm", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-SignedHeaders", valid_607002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607004: Call_GetDataflowGraph_606992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_607004.validator(path, query, header, formData, body)
  let scheme = call_607004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607004.url(scheme.get, call_607004.host, call_607004.base,
                         call_607004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607004, url, valid)

proc call*(call_607005: Call_GetDataflowGraph_606992; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_607006 = newJObject()
  if body != nil:
    body_607006 = body
  result = call_607005.call(nil, nil, nil, nil, body_607006)

var getDataflowGraph* = Call_GetDataflowGraph_606992(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_606993, base: "/",
    url: url_GetDataflowGraph_606994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_607007 = ref object of OpenApiRestCall_605589
proc url_GetDevEndpoint_607009(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevEndpoint_607008(path: JsonNode; query: JsonNode;
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
  var valid_607010 = header.getOrDefault("X-Amz-Target")
  valid_607010 = validateParameter(valid_607010, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_607010 != nil:
    section.add "X-Amz-Target", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Signature")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Signature", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-Content-Sha256", valid_607012
  var valid_607013 = header.getOrDefault("X-Amz-Date")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "X-Amz-Date", valid_607013
  var valid_607014 = header.getOrDefault("X-Amz-Credential")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "X-Amz-Credential", valid_607014
  var valid_607015 = header.getOrDefault("X-Amz-Security-Token")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "X-Amz-Security-Token", valid_607015
  var valid_607016 = header.getOrDefault("X-Amz-Algorithm")
  valid_607016 = validateParameter(valid_607016, JString, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "X-Amz-Algorithm", valid_607016
  var valid_607017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607017 = validateParameter(valid_607017, JString, required = false,
                                 default = nil)
  if valid_607017 != nil:
    section.add "X-Amz-SignedHeaders", valid_607017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607019: Call_GetDevEndpoint_607007; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_607019.validator(path, query, header, formData, body)
  let scheme = call_607019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607019.url(scheme.get, call_607019.host, call_607019.base,
                         call_607019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607019, url, valid)

proc call*(call_607020: Call_GetDevEndpoint_607007; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_607021 = newJObject()
  if body != nil:
    body_607021 = body
  result = call_607020.call(nil, nil, nil, nil, body_607021)

var getDevEndpoint* = Call_GetDevEndpoint_607007(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_607008, base: "/", url: url_GetDevEndpoint_607009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_607022 = ref object of OpenApiRestCall_605589
proc url_GetDevEndpoints_607024(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevEndpoints_607023(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
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
  var valid_607025 = query.getOrDefault("MaxResults")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "MaxResults", valid_607025
  var valid_607026 = query.getOrDefault("NextToken")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "NextToken", valid_607026
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
  var valid_607027 = header.getOrDefault("X-Amz-Target")
  valid_607027 = validateParameter(valid_607027, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_607027 != nil:
    section.add "X-Amz-Target", valid_607027
  var valid_607028 = header.getOrDefault("X-Amz-Signature")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-Signature", valid_607028
  var valid_607029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Content-Sha256", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-Date")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-Date", valid_607030
  var valid_607031 = header.getOrDefault("X-Amz-Credential")
  valid_607031 = validateParameter(valid_607031, JString, required = false,
                                 default = nil)
  if valid_607031 != nil:
    section.add "X-Amz-Credential", valid_607031
  var valid_607032 = header.getOrDefault("X-Amz-Security-Token")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Security-Token", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Algorithm")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Algorithm", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-SignedHeaders", valid_607034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607036: Call_GetDevEndpoints_607022; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_607036.validator(path, query, header, formData, body)
  let scheme = call_607036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607036.url(scheme.get, call_607036.host, call_607036.base,
                         call_607036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607036, url, valid)

proc call*(call_607037: Call_GetDevEndpoints_607022; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607038 = newJObject()
  var body_607039 = newJObject()
  add(query_607038, "MaxResults", newJString(MaxResults))
  add(query_607038, "NextToken", newJString(NextToken))
  if body != nil:
    body_607039 = body
  result = call_607037.call(nil, query_607038, nil, nil, body_607039)

var getDevEndpoints* = Call_GetDevEndpoints_607022(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_607023, base: "/", url: url_GetDevEndpoints_607024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_607040 = ref object of OpenApiRestCall_605589
proc url_GetJob_607042(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_607041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607043 = header.getOrDefault("X-Amz-Target")
  valid_607043 = validateParameter(valid_607043, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_607043 != nil:
    section.add "X-Amz-Target", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Signature")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Signature", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Content-Sha256", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Date")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Date", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Credential")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Credential", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-Security-Token")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-Security-Token", valid_607048
  var valid_607049 = header.getOrDefault("X-Amz-Algorithm")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-Algorithm", valid_607049
  var valid_607050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-SignedHeaders", valid_607050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607052: Call_GetJob_607040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_607052.validator(path, query, header, formData, body)
  let scheme = call_607052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607052.url(scheme.get, call_607052.host, call_607052.base,
                         call_607052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607052, url, valid)

proc call*(call_607053: Call_GetJob_607040; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_607054 = newJObject()
  if body != nil:
    body_607054 = body
  result = call_607053.call(nil, nil, nil, nil, body_607054)

var getJob* = Call_GetJob_607040(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_607041, base: "/",
                              url: url_GetJob_607042,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_607055 = ref object of OpenApiRestCall_605589
proc url_GetJobBookmark_607057(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobBookmark_607056(path: JsonNode; query: JsonNode;
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
  var valid_607058 = header.getOrDefault("X-Amz-Target")
  valid_607058 = validateParameter(valid_607058, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_607058 != nil:
    section.add "X-Amz-Target", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Signature")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Signature", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Content-Sha256", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Date")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Date", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Credential")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Credential", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-Security-Token")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Security-Token", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Algorithm")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Algorithm", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-SignedHeaders", valid_607065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607067: Call_GetJobBookmark_607055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_607067.validator(path, query, header, formData, body)
  let scheme = call_607067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607067.url(scheme.get, call_607067.host, call_607067.base,
                         call_607067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607067, url, valid)

proc call*(call_607068: Call_GetJobBookmark_607055; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_607069 = newJObject()
  if body != nil:
    body_607069 = body
  result = call_607068.call(nil, nil, nil, nil, body_607069)

var getJobBookmark* = Call_GetJobBookmark_607055(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_607056, base: "/", url: url_GetJobBookmark_607057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_607070 = ref object of OpenApiRestCall_605589
proc url_GetJobRun_607072(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobRun_607071(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607073 = header.getOrDefault("X-Amz-Target")
  valid_607073 = validateParameter(valid_607073, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_607073 != nil:
    section.add "X-Amz-Target", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Signature")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Signature", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Content-Sha256", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Date")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Date", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Credential")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Credential", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Security-Token")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Security-Token", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Algorithm")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Algorithm", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-SignedHeaders", valid_607080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607082: Call_GetJobRun_607070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_607082.validator(path, query, header, formData, body)
  let scheme = call_607082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607082.url(scheme.get, call_607082.host, call_607082.base,
                         call_607082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607082, url, valid)

proc call*(call_607083: Call_GetJobRun_607070; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_607084 = newJObject()
  if body != nil:
    body_607084 = body
  result = call_607083.call(nil, nil, nil, nil, body_607084)

var getJobRun* = Call_GetJobRun_607070(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_607071,
                                    base: "/", url: url_GetJobRun_607072,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_607085 = ref object of OpenApiRestCall_605589
proc url_GetJobRuns_607087(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobRuns_607086(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given job definition.
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
  var valid_607088 = query.getOrDefault("MaxResults")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "MaxResults", valid_607088
  var valid_607089 = query.getOrDefault("NextToken")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "NextToken", valid_607089
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
  var valid_607090 = header.getOrDefault("X-Amz-Target")
  valid_607090 = validateParameter(valid_607090, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_607090 != nil:
    section.add "X-Amz-Target", valid_607090
  var valid_607091 = header.getOrDefault("X-Amz-Signature")
  valid_607091 = validateParameter(valid_607091, JString, required = false,
                                 default = nil)
  if valid_607091 != nil:
    section.add "X-Amz-Signature", valid_607091
  var valid_607092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "X-Amz-Content-Sha256", valid_607092
  var valid_607093 = header.getOrDefault("X-Amz-Date")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Date", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Credential")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Credential", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Security-Token")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Security-Token", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Algorithm")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Algorithm", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-SignedHeaders", valid_607097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607099: Call_GetJobRuns_607085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_607099.validator(path, query, header, formData, body)
  let scheme = call_607099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607099.url(scheme.get, call_607099.host, call_607099.base,
                         call_607099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607099, url, valid)

proc call*(call_607100: Call_GetJobRuns_607085; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607101 = newJObject()
  var body_607102 = newJObject()
  add(query_607101, "MaxResults", newJString(MaxResults))
  add(query_607101, "NextToken", newJString(NextToken))
  if body != nil:
    body_607102 = body
  result = call_607100.call(nil, query_607101, nil, nil, body_607102)

var getJobRuns* = Call_GetJobRuns_607085(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_607086,
                                      base: "/", url: url_GetJobRuns_607087,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_607103 = ref object of OpenApiRestCall_605589
proc url_GetJobs_607105(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobs_607104(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all current job definitions.
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
  var valid_607106 = query.getOrDefault("MaxResults")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "MaxResults", valid_607106
  var valid_607107 = query.getOrDefault("NextToken")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "NextToken", valid_607107
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
  var valid_607108 = header.getOrDefault("X-Amz-Target")
  valid_607108 = validateParameter(valid_607108, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_607108 != nil:
    section.add "X-Amz-Target", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Signature")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Signature", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Content-Sha256", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Date")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Date", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Credential")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Credential", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Security-Token")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Security-Token", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Algorithm")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Algorithm", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-SignedHeaders", valid_607115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607117: Call_GetJobs_607103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_607117.validator(path, query, header, formData, body)
  let scheme = call_607117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607117.url(scheme.get, call_607117.host, call_607117.base,
                         call_607117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607117, url, valid)

proc call*(call_607118: Call_GetJobs_607103; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607119 = newJObject()
  var body_607120 = newJObject()
  add(query_607119, "MaxResults", newJString(MaxResults))
  add(query_607119, "NextToken", newJString(NextToken))
  if body != nil:
    body_607120 = body
  result = call_607118.call(nil, query_607119, nil, nil, body_607120)

var getJobs* = Call_GetJobs_607103(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_607104, base: "/",
                                url: url_GetJobs_607105,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_607121 = ref object of OpenApiRestCall_605589
proc url_GetMLTaskRun_607123(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTaskRun_607122(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607124 = header.getOrDefault("X-Amz-Target")
  valid_607124 = validateParameter(valid_607124, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_607124 != nil:
    section.add "X-Amz-Target", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Signature")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Signature", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Content-Sha256", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-Date")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-Date", valid_607127
  var valid_607128 = header.getOrDefault("X-Amz-Credential")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Credential", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Security-Token")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Security-Token", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Algorithm")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Algorithm", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-SignedHeaders", valid_607131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607133: Call_GetMLTaskRun_607121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_607133.validator(path, query, header, formData, body)
  let scheme = call_607133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607133.url(scheme.get, call_607133.host, call_607133.base,
                         call_607133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607133, url, valid)

proc call*(call_607134: Call_GetMLTaskRun_607121; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_607135 = newJObject()
  if body != nil:
    body_607135 = body
  result = call_607134.call(nil, nil, nil, nil, body_607135)

var getMLTaskRun* = Call_GetMLTaskRun_607121(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_607122, base: "/", url: url_GetMLTaskRun_607123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_607136 = ref object of OpenApiRestCall_605589
proc url_GetMLTaskRuns_607138(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTaskRuns_607137(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
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
  var valid_607139 = query.getOrDefault("MaxResults")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "MaxResults", valid_607139
  var valid_607140 = query.getOrDefault("NextToken")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "NextToken", valid_607140
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
  var valid_607141 = header.getOrDefault("X-Amz-Target")
  valid_607141 = validateParameter(valid_607141, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_607141 != nil:
    section.add "X-Amz-Target", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Signature")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Signature", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Content-Sha256", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-Date")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Date", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Credential")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Credential", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Security-Token")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Security-Token", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Algorithm")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Algorithm", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-SignedHeaders", valid_607148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607150: Call_GetMLTaskRuns_607136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_607150.validator(path, query, header, formData, body)
  let scheme = call_607150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607150.url(scheme.get, call_607150.host, call_607150.base,
                         call_607150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607150, url, valid)

proc call*(call_607151: Call_GetMLTaskRuns_607136; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607152 = newJObject()
  var body_607153 = newJObject()
  add(query_607152, "MaxResults", newJString(MaxResults))
  add(query_607152, "NextToken", newJString(NextToken))
  if body != nil:
    body_607153 = body
  result = call_607151.call(nil, query_607152, nil, nil, body_607153)

var getMLTaskRuns* = Call_GetMLTaskRuns_607136(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_607137, base: "/", url: url_GetMLTaskRuns_607138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_607154 = ref object of OpenApiRestCall_605589
proc url_GetMLTransform_607156(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTransform_607155(path: JsonNode; query: JsonNode;
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
  var valid_607157 = header.getOrDefault("X-Amz-Target")
  valid_607157 = validateParameter(valid_607157, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_607157 != nil:
    section.add "X-Amz-Target", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-Signature")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Signature", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-Content-Sha256", valid_607159
  var valid_607160 = header.getOrDefault("X-Amz-Date")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Date", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Credential")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Credential", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Security-Token")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Security-Token", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-Algorithm")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-Algorithm", valid_607163
  var valid_607164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-SignedHeaders", valid_607164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607166: Call_GetMLTransform_607154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_607166.validator(path, query, header, formData, body)
  let scheme = call_607166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607166.url(scheme.get, call_607166.host, call_607166.base,
                         call_607166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607166, url, valid)

proc call*(call_607167: Call_GetMLTransform_607154; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_607168 = newJObject()
  if body != nil:
    body_607168 = body
  result = call_607167.call(nil, nil, nil, nil, body_607168)

var getMLTransform* = Call_GetMLTransform_607154(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_607155, base: "/", url: url_GetMLTransform_607156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_607169 = ref object of OpenApiRestCall_605589
proc url_GetMLTransforms_607171(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTransforms_607170(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
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
  var valid_607172 = query.getOrDefault("MaxResults")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "MaxResults", valid_607172
  var valid_607173 = query.getOrDefault("NextToken")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "NextToken", valid_607173
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
  var valid_607174 = header.getOrDefault("X-Amz-Target")
  valid_607174 = validateParameter(valid_607174, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_607174 != nil:
    section.add "X-Amz-Target", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Signature")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Signature", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Content-Sha256", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Date")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Date", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-Credential")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-Credential", valid_607178
  var valid_607179 = header.getOrDefault("X-Amz-Security-Token")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "X-Amz-Security-Token", valid_607179
  var valid_607180 = header.getOrDefault("X-Amz-Algorithm")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "X-Amz-Algorithm", valid_607180
  var valid_607181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "X-Amz-SignedHeaders", valid_607181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607183: Call_GetMLTransforms_607169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_607183.validator(path, query, header, formData, body)
  let scheme = call_607183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607183.url(scheme.get, call_607183.host, call_607183.base,
                         call_607183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607183, url, valid)

proc call*(call_607184: Call_GetMLTransforms_607169; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607185 = newJObject()
  var body_607186 = newJObject()
  add(query_607185, "MaxResults", newJString(MaxResults))
  add(query_607185, "NextToken", newJString(NextToken))
  if body != nil:
    body_607186 = body
  result = call_607184.call(nil, query_607185, nil, nil, body_607186)

var getMLTransforms* = Call_GetMLTransforms_607169(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_607170, base: "/", url: url_GetMLTransforms_607171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_607187 = ref object of OpenApiRestCall_605589
proc url_GetMapping_607189(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMapping_607188(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607190 = header.getOrDefault("X-Amz-Target")
  valid_607190 = validateParameter(valid_607190, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_607190 != nil:
    section.add "X-Amz-Target", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Signature")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Signature", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Content-Sha256", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-Date")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-Date", valid_607193
  var valid_607194 = header.getOrDefault("X-Amz-Credential")
  valid_607194 = validateParameter(valid_607194, JString, required = false,
                                 default = nil)
  if valid_607194 != nil:
    section.add "X-Amz-Credential", valid_607194
  var valid_607195 = header.getOrDefault("X-Amz-Security-Token")
  valid_607195 = validateParameter(valid_607195, JString, required = false,
                                 default = nil)
  if valid_607195 != nil:
    section.add "X-Amz-Security-Token", valid_607195
  var valid_607196 = header.getOrDefault("X-Amz-Algorithm")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "X-Amz-Algorithm", valid_607196
  var valid_607197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-SignedHeaders", valid_607197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607199: Call_GetMapping_607187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_607199.validator(path, query, header, formData, body)
  let scheme = call_607199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607199.url(scheme.get, call_607199.host, call_607199.base,
                         call_607199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607199, url, valid)

proc call*(call_607200: Call_GetMapping_607187; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_607201 = newJObject()
  if body != nil:
    body_607201 = body
  result = call_607200.call(nil, nil, nil, nil, body_607201)

var getMapping* = Call_GetMapping_607187(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_607188,
                                      base: "/", url: url_GetMapping_607189,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_607202 = ref object of OpenApiRestCall_605589
proc url_GetPartition_607204(protocol: Scheme; host: string; base: string;
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

proc validate_GetPartition_607203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607205 = header.getOrDefault("X-Amz-Target")
  valid_607205 = validateParameter(valid_607205, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_607205 != nil:
    section.add "X-Amz-Target", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Signature")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Signature", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Content-Sha256", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-Date")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-Date", valid_607208
  var valid_607209 = header.getOrDefault("X-Amz-Credential")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-Credential", valid_607209
  var valid_607210 = header.getOrDefault("X-Amz-Security-Token")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "X-Amz-Security-Token", valid_607210
  var valid_607211 = header.getOrDefault("X-Amz-Algorithm")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "X-Amz-Algorithm", valid_607211
  var valid_607212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "X-Amz-SignedHeaders", valid_607212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607214: Call_GetPartition_607202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_607214.validator(path, query, header, formData, body)
  let scheme = call_607214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607214.url(scheme.get, call_607214.host, call_607214.base,
                         call_607214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607214, url, valid)

proc call*(call_607215: Call_GetPartition_607202; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_607216 = newJObject()
  if body != nil:
    body_607216 = body
  result = call_607215.call(nil, nil, nil, nil, body_607216)

var getPartition* = Call_GetPartition_607202(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_607203, base: "/", url: url_GetPartition_607204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_607217 = ref object of OpenApiRestCall_605589
proc url_GetPartitions_607219(protocol: Scheme; host: string; base: string;
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

proc validate_GetPartitions_607218(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the partitions in a table.
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
  var valid_607220 = query.getOrDefault("MaxResults")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "MaxResults", valid_607220
  var valid_607221 = query.getOrDefault("NextToken")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "NextToken", valid_607221
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
  var valid_607222 = header.getOrDefault("X-Amz-Target")
  valid_607222 = validateParameter(valid_607222, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_607222 != nil:
    section.add "X-Amz-Target", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-Signature")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-Signature", valid_607223
  var valid_607224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Content-Sha256", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Date")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Date", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-Credential")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-Credential", valid_607226
  var valid_607227 = header.getOrDefault("X-Amz-Security-Token")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-Security-Token", valid_607227
  var valid_607228 = header.getOrDefault("X-Amz-Algorithm")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "X-Amz-Algorithm", valid_607228
  var valid_607229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-SignedHeaders", valid_607229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607231: Call_GetPartitions_607217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_607231.validator(path, query, header, formData, body)
  let scheme = call_607231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607231.url(scheme.get, call_607231.host, call_607231.base,
                         call_607231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607231, url, valid)

proc call*(call_607232: Call_GetPartitions_607217; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607233 = newJObject()
  var body_607234 = newJObject()
  add(query_607233, "MaxResults", newJString(MaxResults))
  add(query_607233, "NextToken", newJString(NextToken))
  if body != nil:
    body_607234 = body
  result = call_607232.call(nil, query_607233, nil, nil, body_607234)

var getPartitions* = Call_GetPartitions_607217(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_607218, base: "/", url: url_GetPartitions_607219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_607235 = ref object of OpenApiRestCall_605589
proc url_GetPlan_607237(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPlan_607236(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607238 = header.getOrDefault("X-Amz-Target")
  valid_607238 = validateParameter(valid_607238, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_607238 != nil:
    section.add "X-Amz-Target", valid_607238
  var valid_607239 = header.getOrDefault("X-Amz-Signature")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "X-Amz-Signature", valid_607239
  var valid_607240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-Content-Sha256", valid_607240
  var valid_607241 = header.getOrDefault("X-Amz-Date")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-Date", valid_607241
  var valid_607242 = header.getOrDefault("X-Amz-Credential")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Credential", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Security-Token")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Security-Token", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-Algorithm")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-Algorithm", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-SignedHeaders", valid_607245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607247: Call_GetPlan_607235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_607247.validator(path, query, header, formData, body)
  let scheme = call_607247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607247.url(scheme.get, call_607247.host, call_607247.base,
                         call_607247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607247, url, valid)

proc call*(call_607248: Call_GetPlan_607235; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_607249 = newJObject()
  if body != nil:
    body_607249 = body
  result = call_607248.call(nil, nil, nil, nil, body_607249)

var getPlan* = Call_GetPlan_607235(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_607236, base: "/",
                                url: url_GetPlan_607237,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_607250 = ref object of OpenApiRestCall_605589
proc url_GetResourcePolicy_607252(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicy_607251(path: JsonNode; query: JsonNode;
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
  var valid_607253 = header.getOrDefault("X-Amz-Target")
  valid_607253 = validateParameter(valid_607253, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_607253 != nil:
    section.add "X-Amz-Target", valid_607253
  var valid_607254 = header.getOrDefault("X-Amz-Signature")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "X-Amz-Signature", valid_607254
  var valid_607255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607255 = validateParameter(valid_607255, JString, required = false,
                                 default = nil)
  if valid_607255 != nil:
    section.add "X-Amz-Content-Sha256", valid_607255
  var valid_607256 = header.getOrDefault("X-Amz-Date")
  valid_607256 = validateParameter(valid_607256, JString, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "X-Amz-Date", valid_607256
  var valid_607257 = header.getOrDefault("X-Amz-Credential")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "X-Amz-Credential", valid_607257
  var valid_607258 = header.getOrDefault("X-Amz-Security-Token")
  valid_607258 = validateParameter(valid_607258, JString, required = false,
                                 default = nil)
  if valid_607258 != nil:
    section.add "X-Amz-Security-Token", valid_607258
  var valid_607259 = header.getOrDefault("X-Amz-Algorithm")
  valid_607259 = validateParameter(valid_607259, JString, required = false,
                                 default = nil)
  if valid_607259 != nil:
    section.add "X-Amz-Algorithm", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-SignedHeaders", valid_607260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607262: Call_GetResourcePolicy_607250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_607262.validator(path, query, header, formData, body)
  let scheme = call_607262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607262.url(scheme.get, call_607262.host, call_607262.base,
                         call_607262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607262, url, valid)

proc call*(call_607263: Call_GetResourcePolicy_607250; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_607264 = newJObject()
  if body != nil:
    body_607264 = body
  result = call_607263.call(nil, nil, nil, nil, body_607264)

var getResourcePolicy* = Call_GetResourcePolicy_607250(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_607251, base: "/",
    url: url_GetResourcePolicy_607252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_607265 = ref object of OpenApiRestCall_605589
proc url_GetSecurityConfiguration_607267(protocol: Scheme; host: string;
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

proc validate_GetSecurityConfiguration_607266(path: JsonNode; query: JsonNode;
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
  var valid_607268 = header.getOrDefault("X-Amz-Target")
  valid_607268 = validateParameter(valid_607268, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_607268 != nil:
    section.add "X-Amz-Target", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Signature")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Signature", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-Content-Sha256", valid_607270
  var valid_607271 = header.getOrDefault("X-Amz-Date")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "X-Amz-Date", valid_607271
  var valid_607272 = header.getOrDefault("X-Amz-Credential")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "X-Amz-Credential", valid_607272
  var valid_607273 = header.getOrDefault("X-Amz-Security-Token")
  valid_607273 = validateParameter(valid_607273, JString, required = false,
                                 default = nil)
  if valid_607273 != nil:
    section.add "X-Amz-Security-Token", valid_607273
  var valid_607274 = header.getOrDefault("X-Amz-Algorithm")
  valid_607274 = validateParameter(valid_607274, JString, required = false,
                                 default = nil)
  if valid_607274 != nil:
    section.add "X-Amz-Algorithm", valid_607274
  var valid_607275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-SignedHeaders", valid_607275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607277: Call_GetSecurityConfiguration_607265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_607277.validator(path, query, header, formData, body)
  let scheme = call_607277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607277.url(scheme.get, call_607277.host, call_607277.base,
                         call_607277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607277, url, valid)

proc call*(call_607278: Call_GetSecurityConfiguration_607265; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_607279 = newJObject()
  if body != nil:
    body_607279 = body
  result = call_607278.call(nil, nil, nil, nil, body_607279)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_607265(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_607266, base: "/",
    url: url_GetSecurityConfiguration_607267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_607280 = ref object of OpenApiRestCall_605589
proc url_GetSecurityConfigurations_607282(protocol: Scheme; host: string;
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

proc validate_GetSecurityConfigurations_607281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of all security configurations.
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
  var valid_607283 = query.getOrDefault("MaxResults")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "MaxResults", valid_607283
  var valid_607284 = query.getOrDefault("NextToken")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "NextToken", valid_607284
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
  var valid_607285 = header.getOrDefault("X-Amz-Target")
  valid_607285 = validateParameter(valid_607285, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_607285 != nil:
    section.add "X-Amz-Target", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-Signature")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-Signature", valid_607286
  var valid_607287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "X-Amz-Content-Sha256", valid_607287
  var valid_607288 = header.getOrDefault("X-Amz-Date")
  valid_607288 = validateParameter(valid_607288, JString, required = false,
                                 default = nil)
  if valid_607288 != nil:
    section.add "X-Amz-Date", valid_607288
  var valid_607289 = header.getOrDefault("X-Amz-Credential")
  valid_607289 = validateParameter(valid_607289, JString, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "X-Amz-Credential", valid_607289
  var valid_607290 = header.getOrDefault("X-Amz-Security-Token")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Security-Token", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Algorithm")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Algorithm", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-SignedHeaders", valid_607292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607294: Call_GetSecurityConfigurations_607280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_607294.validator(path, query, header, formData, body)
  let scheme = call_607294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607294.url(scheme.get, call_607294.host, call_607294.base,
                         call_607294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607294, url, valid)

proc call*(call_607295: Call_GetSecurityConfigurations_607280; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607296 = newJObject()
  var body_607297 = newJObject()
  add(query_607296, "MaxResults", newJString(MaxResults))
  add(query_607296, "NextToken", newJString(NextToken))
  if body != nil:
    body_607297 = body
  result = call_607295.call(nil, query_607296, nil, nil, body_607297)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_607280(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_607281, base: "/",
    url: url_GetSecurityConfigurations_607282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_607298 = ref object of OpenApiRestCall_605589
proc url_GetTable_607300(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTable_607299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607301 = header.getOrDefault("X-Amz-Target")
  valid_607301 = validateParameter(valid_607301, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_607301 != nil:
    section.add "X-Amz-Target", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Signature")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Signature", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Content-Sha256", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-Date")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-Date", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Credential")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Credential", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Security-Token")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Security-Token", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Algorithm")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Algorithm", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-SignedHeaders", valid_607308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607310: Call_GetTable_607298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_607310.validator(path, query, header, formData, body)
  let scheme = call_607310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607310.url(scheme.get, call_607310.host, call_607310.base,
                         call_607310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607310, url, valid)

proc call*(call_607311: Call_GetTable_607298; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_607312 = newJObject()
  if body != nil:
    body_607312 = body
  result = call_607311.call(nil, nil, nil, nil, body_607312)

var getTable* = Call_GetTable_607298(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_607299, base: "/",
                                  url: url_GetTable_607300,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_607313 = ref object of OpenApiRestCall_605589
proc url_GetTableVersion_607315(protocol: Scheme; host: string; base: string;
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

proc validate_GetTableVersion_607314(path: JsonNode; query: JsonNode;
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
  var valid_607316 = header.getOrDefault("X-Amz-Target")
  valid_607316 = validateParameter(valid_607316, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_607316 != nil:
    section.add "X-Amz-Target", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Signature")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Signature", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-Content-Sha256", valid_607318
  var valid_607319 = header.getOrDefault("X-Amz-Date")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Date", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Credential")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Credential", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Security-Token")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Security-Token", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Algorithm")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Algorithm", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-SignedHeaders", valid_607323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607325: Call_GetTableVersion_607313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_607325.validator(path, query, header, formData, body)
  let scheme = call_607325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607325.url(scheme.get, call_607325.host, call_607325.base,
                         call_607325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607325, url, valid)

proc call*(call_607326: Call_GetTableVersion_607313; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_607327 = newJObject()
  if body != nil:
    body_607327 = body
  result = call_607326.call(nil, nil, nil, nil, body_607327)

var getTableVersion* = Call_GetTableVersion_607313(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_607314, base: "/", url: url_GetTableVersion_607315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_607328 = ref object of OpenApiRestCall_605589
proc url_GetTableVersions_607330(protocol: Scheme; host: string; base: string;
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

proc validate_GetTableVersions_607329(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of strings that identify available versions of a specified table.
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
  var valid_607331 = query.getOrDefault("MaxResults")
  valid_607331 = validateParameter(valid_607331, JString, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "MaxResults", valid_607331
  var valid_607332 = query.getOrDefault("NextToken")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "NextToken", valid_607332
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
  var valid_607333 = header.getOrDefault("X-Amz-Target")
  valid_607333 = validateParameter(valid_607333, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_607333 != nil:
    section.add "X-Amz-Target", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Signature")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Signature", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Content-Sha256", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Date")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Date", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Credential")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Credential", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Security-Token")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Security-Token", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Algorithm")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Algorithm", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-SignedHeaders", valid_607340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607342: Call_GetTableVersions_607328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_607342.validator(path, query, header, formData, body)
  let scheme = call_607342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607342.url(scheme.get, call_607342.host, call_607342.base,
                         call_607342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607342, url, valid)

proc call*(call_607343: Call_GetTableVersions_607328; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607344 = newJObject()
  var body_607345 = newJObject()
  add(query_607344, "MaxResults", newJString(MaxResults))
  add(query_607344, "NextToken", newJString(NextToken))
  if body != nil:
    body_607345 = body
  result = call_607343.call(nil, query_607344, nil, nil, body_607345)

var getTableVersions* = Call_GetTableVersions_607328(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_607329, base: "/",
    url: url_GetTableVersions_607330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_607346 = ref object of OpenApiRestCall_605589
proc url_GetTables_607348(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTables_607347(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
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
  var valid_607349 = query.getOrDefault("MaxResults")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "MaxResults", valid_607349
  var valid_607350 = query.getOrDefault("NextToken")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "NextToken", valid_607350
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
  var valid_607351 = header.getOrDefault("X-Amz-Target")
  valid_607351 = validateParameter(valid_607351, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_607351 != nil:
    section.add "X-Amz-Target", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Signature")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Signature", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Content-Sha256", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Date")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Date", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Credential")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Credential", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Security-Token")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Security-Token", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-Algorithm")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-Algorithm", valid_607357
  var valid_607358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607358 = validateParameter(valid_607358, JString, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "X-Amz-SignedHeaders", valid_607358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607360: Call_GetTables_607346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_607360.validator(path, query, header, formData, body)
  let scheme = call_607360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607360.url(scheme.get, call_607360.host, call_607360.base,
                         call_607360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607360, url, valid)

proc call*(call_607361: Call_GetTables_607346; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607362 = newJObject()
  var body_607363 = newJObject()
  add(query_607362, "MaxResults", newJString(MaxResults))
  add(query_607362, "NextToken", newJString(NextToken))
  if body != nil:
    body_607363 = body
  result = call_607361.call(nil, query_607362, nil, nil, body_607363)

var getTables* = Call_GetTables_607346(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_607347,
                                    base: "/", url: url_GetTables_607348,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_607364 = ref object of OpenApiRestCall_605589
proc url_GetTags_607366(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_607365(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607367 = header.getOrDefault("X-Amz-Target")
  valid_607367 = validateParameter(valid_607367, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_607367 != nil:
    section.add "X-Amz-Target", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Signature")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Signature", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Content-Sha256", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Date")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Date", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Credential")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Credential", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Security-Token")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Security-Token", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-Algorithm")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-Algorithm", valid_607373
  var valid_607374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-SignedHeaders", valid_607374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607376: Call_GetTags_607364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_607376.validator(path, query, header, formData, body)
  let scheme = call_607376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607376.url(scheme.get, call_607376.host, call_607376.base,
                         call_607376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607376, url, valid)

proc call*(call_607377: Call_GetTags_607364; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_607378 = newJObject()
  if body != nil:
    body_607378 = body
  result = call_607377.call(nil, nil, nil, nil, body_607378)

var getTags* = Call_GetTags_607364(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_607365, base: "/",
                                url: url_GetTags_607366,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_607379 = ref object of OpenApiRestCall_605589
proc url_GetTrigger_607381(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTrigger_607380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607382 = header.getOrDefault("X-Amz-Target")
  valid_607382 = validateParameter(valid_607382, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_607382 != nil:
    section.add "X-Amz-Target", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Signature")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Signature", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Content-Sha256", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Date")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Date", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Credential")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Credential", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Security-Token")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Security-Token", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Algorithm")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Algorithm", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-SignedHeaders", valid_607389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607391: Call_GetTrigger_607379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_607391.validator(path, query, header, formData, body)
  let scheme = call_607391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607391.url(scheme.get, call_607391.host, call_607391.base,
                         call_607391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607391, url, valid)

proc call*(call_607392: Call_GetTrigger_607379; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_607393 = newJObject()
  if body != nil:
    body_607393 = body
  result = call_607392.call(nil, nil, nil, nil, body_607393)

var getTrigger* = Call_GetTrigger_607379(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_607380,
                                      base: "/", url: url_GetTrigger_607381,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_607394 = ref object of OpenApiRestCall_605589
proc url_GetTriggers_607396(protocol: Scheme; host: string; base: string;
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

proc validate_GetTriggers_607395(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the triggers associated with a job.
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
  var valid_607397 = query.getOrDefault("MaxResults")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "MaxResults", valid_607397
  var valid_607398 = query.getOrDefault("NextToken")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "NextToken", valid_607398
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
  var valid_607399 = header.getOrDefault("X-Amz-Target")
  valid_607399 = validateParameter(valid_607399, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_607399 != nil:
    section.add "X-Amz-Target", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Signature")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Signature", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-Content-Sha256", valid_607401
  var valid_607402 = header.getOrDefault("X-Amz-Date")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Date", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-Credential")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-Credential", valid_607403
  var valid_607404 = header.getOrDefault("X-Amz-Security-Token")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Security-Token", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Algorithm")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Algorithm", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-SignedHeaders", valid_607406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607408: Call_GetTriggers_607394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_607408.validator(path, query, header, formData, body)
  let scheme = call_607408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607408.url(scheme.get, call_607408.host, call_607408.base,
                         call_607408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607408, url, valid)

proc call*(call_607409: Call_GetTriggers_607394; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607410 = newJObject()
  var body_607411 = newJObject()
  add(query_607410, "MaxResults", newJString(MaxResults))
  add(query_607410, "NextToken", newJString(NextToken))
  if body != nil:
    body_607411 = body
  result = call_607409.call(nil, query_607410, nil, nil, body_607411)

var getTriggers* = Call_GetTriggers_607394(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_607395,
                                        base: "/", url: url_GetTriggers_607396,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_607412 = ref object of OpenApiRestCall_605589
proc url_GetUserDefinedFunction_607414(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserDefinedFunction_607413(path: JsonNode; query: JsonNode;
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
  var valid_607415 = header.getOrDefault("X-Amz-Target")
  valid_607415 = validateParameter(valid_607415, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_607415 != nil:
    section.add "X-Amz-Target", valid_607415
  var valid_607416 = header.getOrDefault("X-Amz-Signature")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-Signature", valid_607416
  var valid_607417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Content-Sha256", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-Date")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Date", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-Credential")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-Credential", valid_607419
  var valid_607420 = header.getOrDefault("X-Amz-Security-Token")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-Security-Token", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Algorithm")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Algorithm", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-SignedHeaders", valid_607422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607424: Call_GetUserDefinedFunction_607412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_607424.validator(path, query, header, formData, body)
  let scheme = call_607424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607424.url(scheme.get, call_607424.host, call_607424.base,
                         call_607424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607424, url, valid)

proc call*(call_607425: Call_GetUserDefinedFunction_607412; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_607426 = newJObject()
  if body != nil:
    body_607426 = body
  result = call_607425.call(nil, nil, nil, nil, body_607426)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_607412(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_607413, base: "/",
    url: url_GetUserDefinedFunction_607414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_607427 = ref object of OpenApiRestCall_605589
proc url_GetUserDefinedFunctions_607429(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetUserDefinedFunctions_607428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves multiple function definitions from the Data Catalog.
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
  var valid_607430 = query.getOrDefault("MaxResults")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "MaxResults", valid_607430
  var valid_607431 = query.getOrDefault("NextToken")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "NextToken", valid_607431
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
  var valid_607432 = header.getOrDefault("X-Amz-Target")
  valid_607432 = validateParameter(valid_607432, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_607432 != nil:
    section.add "X-Amz-Target", valid_607432
  var valid_607433 = header.getOrDefault("X-Amz-Signature")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "X-Amz-Signature", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-Content-Sha256", valid_607434
  var valid_607435 = header.getOrDefault("X-Amz-Date")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-Date", valid_607435
  var valid_607436 = header.getOrDefault("X-Amz-Credential")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "X-Amz-Credential", valid_607436
  var valid_607437 = header.getOrDefault("X-Amz-Security-Token")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "X-Amz-Security-Token", valid_607437
  var valid_607438 = header.getOrDefault("X-Amz-Algorithm")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Algorithm", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-SignedHeaders", valid_607439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607441: Call_GetUserDefinedFunctions_607427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_607441.validator(path, query, header, formData, body)
  let scheme = call_607441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607441.url(scheme.get, call_607441.host, call_607441.base,
                         call_607441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607441, url, valid)

proc call*(call_607442: Call_GetUserDefinedFunctions_607427; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607443 = newJObject()
  var body_607444 = newJObject()
  add(query_607443, "MaxResults", newJString(MaxResults))
  add(query_607443, "NextToken", newJString(NextToken))
  if body != nil:
    body_607444 = body
  result = call_607442.call(nil, query_607443, nil, nil, body_607444)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_607427(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_607428, base: "/",
    url: url_GetUserDefinedFunctions_607429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_607445 = ref object of OpenApiRestCall_605589
proc url_GetWorkflow_607447(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflow_607446(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607448 = header.getOrDefault("X-Amz-Target")
  valid_607448 = validateParameter(valid_607448, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_607448 != nil:
    section.add "X-Amz-Target", valid_607448
  var valid_607449 = header.getOrDefault("X-Amz-Signature")
  valid_607449 = validateParameter(valid_607449, JString, required = false,
                                 default = nil)
  if valid_607449 != nil:
    section.add "X-Amz-Signature", valid_607449
  var valid_607450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607450 = validateParameter(valid_607450, JString, required = false,
                                 default = nil)
  if valid_607450 != nil:
    section.add "X-Amz-Content-Sha256", valid_607450
  var valid_607451 = header.getOrDefault("X-Amz-Date")
  valid_607451 = validateParameter(valid_607451, JString, required = false,
                                 default = nil)
  if valid_607451 != nil:
    section.add "X-Amz-Date", valid_607451
  var valid_607452 = header.getOrDefault("X-Amz-Credential")
  valid_607452 = validateParameter(valid_607452, JString, required = false,
                                 default = nil)
  if valid_607452 != nil:
    section.add "X-Amz-Credential", valid_607452
  var valid_607453 = header.getOrDefault("X-Amz-Security-Token")
  valid_607453 = validateParameter(valid_607453, JString, required = false,
                                 default = nil)
  if valid_607453 != nil:
    section.add "X-Amz-Security-Token", valid_607453
  var valid_607454 = header.getOrDefault("X-Amz-Algorithm")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "X-Amz-Algorithm", valid_607454
  var valid_607455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "X-Amz-SignedHeaders", valid_607455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607457: Call_GetWorkflow_607445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_607457.validator(path, query, header, formData, body)
  let scheme = call_607457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607457.url(scheme.get, call_607457.host, call_607457.base,
                         call_607457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607457, url, valid)

proc call*(call_607458: Call_GetWorkflow_607445; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_607459 = newJObject()
  if body != nil:
    body_607459 = body
  result = call_607458.call(nil, nil, nil, nil, body_607459)

var getWorkflow* = Call_GetWorkflow_607445(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_607446,
                                        base: "/", url: url_GetWorkflow_607447,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_607460 = ref object of OpenApiRestCall_605589
proc url_GetWorkflowRun_607462(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflowRun_607461(path: JsonNode; query: JsonNode;
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
  var valid_607463 = header.getOrDefault("X-Amz-Target")
  valid_607463 = validateParameter(valid_607463, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_607463 != nil:
    section.add "X-Amz-Target", valid_607463
  var valid_607464 = header.getOrDefault("X-Amz-Signature")
  valid_607464 = validateParameter(valid_607464, JString, required = false,
                                 default = nil)
  if valid_607464 != nil:
    section.add "X-Amz-Signature", valid_607464
  var valid_607465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607465 = validateParameter(valid_607465, JString, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "X-Amz-Content-Sha256", valid_607465
  var valid_607466 = header.getOrDefault("X-Amz-Date")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "X-Amz-Date", valid_607466
  var valid_607467 = header.getOrDefault("X-Amz-Credential")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-Credential", valid_607467
  var valid_607468 = header.getOrDefault("X-Amz-Security-Token")
  valid_607468 = validateParameter(valid_607468, JString, required = false,
                                 default = nil)
  if valid_607468 != nil:
    section.add "X-Amz-Security-Token", valid_607468
  var valid_607469 = header.getOrDefault("X-Amz-Algorithm")
  valid_607469 = validateParameter(valid_607469, JString, required = false,
                                 default = nil)
  if valid_607469 != nil:
    section.add "X-Amz-Algorithm", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-SignedHeaders", valid_607470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607472: Call_GetWorkflowRun_607460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_607472.validator(path, query, header, formData, body)
  let scheme = call_607472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607472.url(scheme.get, call_607472.host, call_607472.base,
                         call_607472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607472, url, valid)

proc call*(call_607473: Call_GetWorkflowRun_607460; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_607474 = newJObject()
  if body != nil:
    body_607474 = body
  result = call_607473.call(nil, nil, nil, nil, body_607474)

var getWorkflowRun* = Call_GetWorkflowRun_607460(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_607461, base: "/", url: url_GetWorkflowRun_607462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_607475 = ref object of OpenApiRestCall_605589
proc url_GetWorkflowRunProperties_607477(protocol: Scheme; host: string;
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

proc validate_GetWorkflowRunProperties_607476(path: JsonNode; query: JsonNode;
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
  var valid_607478 = header.getOrDefault("X-Amz-Target")
  valid_607478 = validateParameter(valid_607478, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_607478 != nil:
    section.add "X-Amz-Target", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-Signature")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-Signature", valid_607479
  var valid_607480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "X-Amz-Content-Sha256", valid_607480
  var valid_607481 = header.getOrDefault("X-Amz-Date")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "X-Amz-Date", valid_607481
  var valid_607482 = header.getOrDefault("X-Amz-Credential")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-Credential", valid_607482
  var valid_607483 = header.getOrDefault("X-Amz-Security-Token")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "X-Amz-Security-Token", valid_607483
  var valid_607484 = header.getOrDefault("X-Amz-Algorithm")
  valid_607484 = validateParameter(valid_607484, JString, required = false,
                                 default = nil)
  if valid_607484 != nil:
    section.add "X-Amz-Algorithm", valid_607484
  var valid_607485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-SignedHeaders", valid_607485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607487: Call_GetWorkflowRunProperties_607475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_607487.validator(path, query, header, formData, body)
  let scheme = call_607487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607487.url(scheme.get, call_607487.host, call_607487.base,
                         call_607487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607487, url, valid)

proc call*(call_607488: Call_GetWorkflowRunProperties_607475; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_607489 = newJObject()
  if body != nil:
    body_607489 = body
  result = call_607488.call(nil, nil, nil, nil, body_607489)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_607475(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_607476, base: "/",
    url: url_GetWorkflowRunProperties_607477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_607490 = ref object of OpenApiRestCall_605589
proc url_GetWorkflowRuns_607492(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflowRuns_607491(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given workflow.
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
  var valid_607493 = query.getOrDefault("MaxResults")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "MaxResults", valid_607493
  var valid_607494 = query.getOrDefault("NextToken")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "NextToken", valid_607494
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
  var valid_607495 = header.getOrDefault("X-Amz-Target")
  valid_607495 = validateParameter(valid_607495, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_607495 != nil:
    section.add "X-Amz-Target", valid_607495
  var valid_607496 = header.getOrDefault("X-Amz-Signature")
  valid_607496 = validateParameter(valid_607496, JString, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "X-Amz-Signature", valid_607496
  var valid_607497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607497 = validateParameter(valid_607497, JString, required = false,
                                 default = nil)
  if valid_607497 != nil:
    section.add "X-Amz-Content-Sha256", valid_607497
  var valid_607498 = header.getOrDefault("X-Amz-Date")
  valid_607498 = validateParameter(valid_607498, JString, required = false,
                                 default = nil)
  if valid_607498 != nil:
    section.add "X-Amz-Date", valid_607498
  var valid_607499 = header.getOrDefault("X-Amz-Credential")
  valid_607499 = validateParameter(valid_607499, JString, required = false,
                                 default = nil)
  if valid_607499 != nil:
    section.add "X-Amz-Credential", valid_607499
  var valid_607500 = header.getOrDefault("X-Amz-Security-Token")
  valid_607500 = validateParameter(valid_607500, JString, required = false,
                                 default = nil)
  if valid_607500 != nil:
    section.add "X-Amz-Security-Token", valid_607500
  var valid_607501 = header.getOrDefault("X-Amz-Algorithm")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "X-Amz-Algorithm", valid_607501
  var valid_607502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "X-Amz-SignedHeaders", valid_607502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607504: Call_GetWorkflowRuns_607490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_607504.validator(path, query, header, formData, body)
  let scheme = call_607504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607504.url(scheme.get, call_607504.host, call_607504.base,
                         call_607504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607504, url, valid)

proc call*(call_607505: Call_GetWorkflowRuns_607490; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607506 = newJObject()
  var body_607507 = newJObject()
  add(query_607506, "MaxResults", newJString(MaxResults))
  add(query_607506, "NextToken", newJString(NextToken))
  if body != nil:
    body_607507 = body
  result = call_607505.call(nil, query_607506, nil, nil, body_607507)

var getWorkflowRuns* = Call_GetWorkflowRuns_607490(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_607491, base: "/", url: url_GetWorkflowRuns_607492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_607508 = ref object of OpenApiRestCall_605589
proc url_ImportCatalogToGlue_607510(protocol: Scheme; host: string; base: string;
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

proc validate_ImportCatalogToGlue_607509(path: JsonNode; query: JsonNode;
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
  var valid_607511 = header.getOrDefault("X-Amz-Target")
  valid_607511 = validateParameter(valid_607511, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_607511 != nil:
    section.add "X-Amz-Target", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Signature")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Signature", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Content-Sha256", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-Date")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Date", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Credential")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Credential", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Security-Token")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Security-Token", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Algorithm")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Algorithm", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-SignedHeaders", valid_607518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607520: Call_ImportCatalogToGlue_607508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_607520.validator(path, query, header, formData, body)
  let scheme = call_607520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607520.url(scheme.get, call_607520.host, call_607520.base,
                         call_607520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607520, url, valid)

proc call*(call_607521: Call_ImportCatalogToGlue_607508; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_607522 = newJObject()
  if body != nil:
    body_607522 = body
  result = call_607521.call(nil, nil, nil, nil, body_607522)

var importCatalogToGlue* = Call_ImportCatalogToGlue_607508(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_607509, base: "/",
    url: url_ImportCatalogToGlue_607510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_607523 = ref object of OpenApiRestCall_605589
proc url_ListCrawlers_607525(protocol: Scheme; host: string; base: string;
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

proc validate_ListCrawlers_607524(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_607526 = query.getOrDefault("MaxResults")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "MaxResults", valid_607526
  var valid_607527 = query.getOrDefault("NextToken")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "NextToken", valid_607527
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
  var valid_607528 = header.getOrDefault("X-Amz-Target")
  valid_607528 = validateParameter(valid_607528, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_607528 != nil:
    section.add "X-Amz-Target", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-Signature")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-Signature", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Content-Sha256", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-Date")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-Date", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-Credential")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-Credential", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-Security-Token")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Security-Token", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Algorithm")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Algorithm", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-SignedHeaders", valid_607535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607537: Call_ListCrawlers_607523; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_607537.validator(path, query, header, formData, body)
  let scheme = call_607537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607537.url(scheme.get, call_607537.host, call_607537.base,
                         call_607537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607537, url, valid)

proc call*(call_607538: Call_ListCrawlers_607523; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607539 = newJObject()
  var body_607540 = newJObject()
  add(query_607539, "MaxResults", newJString(MaxResults))
  add(query_607539, "NextToken", newJString(NextToken))
  if body != nil:
    body_607540 = body
  result = call_607538.call(nil, query_607539, nil, nil, body_607540)

var listCrawlers* = Call_ListCrawlers_607523(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_607524, base: "/", url: url_ListCrawlers_607525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_607541 = ref object of OpenApiRestCall_605589
proc url_ListDevEndpoints_607543(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevEndpoints_607542(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_607544 = query.getOrDefault("MaxResults")
  valid_607544 = validateParameter(valid_607544, JString, required = false,
                                 default = nil)
  if valid_607544 != nil:
    section.add "MaxResults", valid_607544
  var valid_607545 = query.getOrDefault("NextToken")
  valid_607545 = validateParameter(valid_607545, JString, required = false,
                                 default = nil)
  if valid_607545 != nil:
    section.add "NextToken", valid_607545
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
  var valid_607546 = header.getOrDefault("X-Amz-Target")
  valid_607546 = validateParameter(valid_607546, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_607546 != nil:
    section.add "X-Amz-Target", valid_607546
  var valid_607547 = header.getOrDefault("X-Amz-Signature")
  valid_607547 = validateParameter(valid_607547, JString, required = false,
                                 default = nil)
  if valid_607547 != nil:
    section.add "X-Amz-Signature", valid_607547
  var valid_607548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Content-Sha256", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Date")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Date", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Credential")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Credential", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Security-Token")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Security-Token", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Algorithm")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Algorithm", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-SignedHeaders", valid_607553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607555: Call_ListDevEndpoints_607541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_607555.validator(path, query, header, formData, body)
  let scheme = call_607555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607555.url(scheme.get, call_607555.host, call_607555.base,
                         call_607555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607555, url, valid)

proc call*(call_607556: Call_ListDevEndpoints_607541; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607557 = newJObject()
  var body_607558 = newJObject()
  add(query_607557, "MaxResults", newJString(MaxResults))
  add(query_607557, "NextToken", newJString(NextToken))
  if body != nil:
    body_607558 = body
  result = call_607556.call(nil, query_607557, nil, nil, body_607558)

var listDevEndpoints* = Call_ListDevEndpoints_607541(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_607542, base: "/",
    url: url_ListDevEndpoints_607543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_607559 = ref object of OpenApiRestCall_605589
proc url_ListJobs_607561(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_607560(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_607562 = query.getOrDefault("MaxResults")
  valid_607562 = validateParameter(valid_607562, JString, required = false,
                                 default = nil)
  if valid_607562 != nil:
    section.add "MaxResults", valid_607562
  var valid_607563 = query.getOrDefault("NextToken")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "NextToken", valid_607563
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
  var valid_607564 = header.getOrDefault("X-Amz-Target")
  valid_607564 = validateParameter(valid_607564, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_607564 != nil:
    section.add "X-Amz-Target", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Signature")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Signature", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Content-Sha256", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Date")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Date", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Credential")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Credential", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-Security-Token")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-Security-Token", valid_607569
  var valid_607570 = header.getOrDefault("X-Amz-Algorithm")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-Algorithm", valid_607570
  var valid_607571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "X-Amz-SignedHeaders", valid_607571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607573: Call_ListJobs_607559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_607573.validator(path, query, header, formData, body)
  let scheme = call_607573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607573.url(scheme.get, call_607573.host, call_607573.base,
                         call_607573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607573, url, valid)

proc call*(call_607574: Call_ListJobs_607559; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607575 = newJObject()
  var body_607576 = newJObject()
  add(query_607575, "MaxResults", newJString(MaxResults))
  add(query_607575, "NextToken", newJString(NextToken))
  if body != nil:
    body_607576 = body
  result = call_607574.call(nil, query_607575, nil, nil, body_607576)

var listJobs* = Call_ListJobs_607559(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_607560, base: "/",
                                  url: url_ListJobs_607561,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_607577 = ref object of OpenApiRestCall_605589
proc url_ListTriggers_607579(protocol: Scheme; host: string; base: string;
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

proc validate_ListTriggers_607578(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
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
  var valid_607580 = query.getOrDefault("MaxResults")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "MaxResults", valid_607580
  var valid_607581 = query.getOrDefault("NextToken")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "NextToken", valid_607581
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
  var valid_607582 = header.getOrDefault("X-Amz-Target")
  valid_607582 = validateParameter(valid_607582, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_607582 != nil:
    section.add "X-Amz-Target", valid_607582
  var valid_607583 = header.getOrDefault("X-Amz-Signature")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "X-Amz-Signature", valid_607583
  var valid_607584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607584 = validateParameter(valid_607584, JString, required = false,
                                 default = nil)
  if valid_607584 != nil:
    section.add "X-Amz-Content-Sha256", valid_607584
  var valid_607585 = header.getOrDefault("X-Amz-Date")
  valid_607585 = validateParameter(valid_607585, JString, required = false,
                                 default = nil)
  if valid_607585 != nil:
    section.add "X-Amz-Date", valid_607585
  var valid_607586 = header.getOrDefault("X-Amz-Credential")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "X-Amz-Credential", valid_607586
  var valid_607587 = header.getOrDefault("X-Amz-Security-Token")
  valid_607587 = validateParameter(valid_607587, JString, required = false,
                                 default = nil)
  if valid_607587 != nil:
    section.add "X-Amz-Security-Token", valid_607587
  var valid_607588 = header.getOrDefault("X-Amz-Algorithm")
  valid_607588 = validateParameter(valid_607588, JString, required = false,
                                 default = nil)
  if valid_607588 != nil:
    section.add "X-Amz-Algorithm", valid_607588
  var valid_607589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "X-Amz-SignedHeaders", valid_607589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607591: Call_ListTriggers_607577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_607591.validator(path, query, header, formData, body)
  let scheme = call_607591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607591.url(scheme.get, call_607591.host, call_607591.base,
                         call_607591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607591, url, valid)

proc call*(call_607592: Call_ListTriggers_607577; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607593 = newJObject()
  var body_607594 = newJObject()
  add(query_607593, "MaxResults", newJString(MaxResults))
  add(query_607593, "NextToken", newJString(NextToken))
  if body != nil:
    body_607594 = body
  result = call_607592.call(nil, query_607593, nil, nil, body_607594)

var listTriggers* = Call_ListTriggers_607577(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_607578, base: "/", url: url_ListTriggers_607579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_607595 = ref object of OpenApiRestCall_605589
proc url_ListWorkflows_607597(protocol: Scheme; host: string; base: string;
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

proc validate_ListWorkflows_607596(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists names of workflows created in the account.
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
  var valid_607598 = query.getOrDefault("MaxResults")
  valid_607598 = validateParameter(valid_607598, JString, required = false,
                                 default = nil)
  if valid_607598 != nil:
    section.add "MaxResults", valid_607598
  var valid_607599 = query.getOrDefault("NextToken")
  valid_607599 = validateParameter(valid_607599, JString, required = false,
                                 default = nil)
  if valid_607599 != nil:
    section.add "NextToken", valid_607599
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
  var valid_607600 = header.getOrDefault("X-Amz-Target")
  valid_607600 = validateParameter(valid_607600, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_607600 != nil:
    section.add "X-Amz-Target", valid_607600
  var valid_607601 = header.getOrDefault("X-Amz-Signature")
  valid_607601 = validateParameter(valid_607601, JString, required = false,
                                 default = nil)
  if valid_607601 != nil:
    section.add "X-Amz-Signature", valid_607601
  var valid_607602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "X-Amz-Content-Sha256", valid_607602
  var valid_607603 = header.getOrDefault("X-Amz-Date")
  valid_607603 = validateParameter(valid_607603, JString, required = false,
                                 default = nil)
  if valid_607603 != nil:
    section.add "X-Amz-Date", valid_607603
  var valid_607604 = header.getOrDefault("X-Amz-Credential")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-Credential", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-Security-Token")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Security-Token", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Algorithm")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Algorithm", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-SignedHeaders", valid_607607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607609: Call_ListWorkflows_607595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_607609.validator(path, query, header, formData, body)
  let scheme = call_607609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607609.url(scheme.get, call_607609.host, call_607609.base,
                         call_607609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607609, url, valid)

proc call*(call_607610: Call_ListWorkflows_607595; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607611 = newJObject()
  var body_607612 = newJObject()
  add(query_607611, "MaxResults", newJString(MaxResults))
  add(query_607611, "NextToken", newJString(NextToken))
  if body != nil:
    body_607612 = body
  result = call_607610.call(nil, query_607611, nil, nil, body_607612)

var listWorkflows* = Call_ListWorkflows_607595(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_607596, base: "/", url: url_ListWorkflows_607597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_607613 = ref object of OpenApiRestCall_605589
proc url_PutDataCatalogEncryptionSettings_607615(protocol: Scheme; host: string;
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

proc validate_PutDataCatalogEncryptionSettings_607614(path: JsonNode;
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
  var valid_607616 = header.getOrDefault("X-Amz-Target")
  valid_607616 = validateParameter(valid_607616, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_607616 != nil:
    section.add "X-Amz-Target", valid_607616
  var valid_607617 = header.getOrDefault("X-Amz-Signature")
  valid_607617 = validateParameter(valid_607617, JString, required = false,
                                 default = nil)
  if valid_607617 != nil:
    section.add "X-Amz-Signature", valid_607617
  var valid_607618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607618 = validateParameter(valid_607618, JString, required = false,
                                 default = nil)
  if valid_607618 != nil:
    section.add "X-Amz-Content-Sha256", valid_607618
  var valid_607619 = header.getOrDefault("X-Amz-Date")
  valid_607619 = validateParameter(valid_607619, JString, required = false,
                                 default = nil)
  if valid_607619 != nil:
    section.add "X-Amz-Date", valid_607619
  var valid_607620 = header.getOrDefault("X-Amz-Credential")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "X-Amz-Credential", valid_607620
  var valid_607621 = header.getOrDefault("X-Amz-Security-Token")
  valid_607621 = validateParameter(valid_607621, JString, required = false,
                                 default = nil)
  if valid_607621 != nil:
    section.add "X-Amz-Security-Token", valid_607621
  var valid_607622 = header.getOrDefault("X-Amz-Algorithm")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "X-Amz-Algorithm", valid_607622
  var valid_607623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-SignedHeaders", valid_607623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607625: Call_PutDataCatalogEncryptionSettings_607613;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_607625.validator(path, query, header, formData, body)
  let scheme = call_607625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607625.url(scheme.get, call_607625.host, call_607625.base,
                         call_607625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607625, url, valid)

proc call*(call_607626: Call_PutDataCatalogEncryptionSettings_607613;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_607627 = newJObject()
  if body != nil:
    body_607627 = body
  result = call_607626.call(nil, nil, nil, nil, body_607627)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_607613(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_607614, base: "/",
    url: url_PutDataCatalogEncryptionSettings_607615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_607628 = ref object of OpenApiRestCall_605589
proc url_PutResourcePolicy_607630(protocol: Scheme; host: string; base: string;
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

proc validate_PutResourcePolicy_607629(path: JsonNode; query: JsonNode;
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
  var valid_607631 = header.getOrDefault("X-Amz-Target")
  valid_607631 = validateParameter(valid_607631, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_607631 != nil:
    section.add "X-Amz-Target", valid_607631
  var valid_607632 = header.getOrDefault("X-Amz-Signature")
  valid_607632 = validateParameter(valid_607632, JString, required = false,
                                 default = nil)
  if valid_607632 != nil:
    section.add "X-Amz-Signature", valid_607632
  var valid_607633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607633 = validateParameter(valid_607633, JString, required = false,
                                 default = nil)
  if valid_607633 != nil:
    section.add "X-Amz-Content-Sha256", valid_607633
  var valid_607634 = header.getOrDefault("X-Amz-Date")
  valid_607634 = validateParameter(valid_607634, JString, required = false,
                                 default = nil)
  if valid_607634 != nil:
    section.add "X-Amz-Date", valid_607634
  var valid_607635 = header.getOrDefault("X-Amz-Credential")
  valid_607635 = validateParameter(valid_607635, JString, required = false,
                                 default = nil)
  if valid_607635 != nil:
    section.add "X-Amz-Credential", valid_607635
  var valid_607636 = header.getOrDefault("X-Amz-Security-Token")
  valid_607636 = validateParameter(valid_607636, JString, required = false,
                                 default = nil)
  if valid_607636 != nil:
    section.add "X-Amz-Security-Token", valid_607636
  var valid_607637 = header.getOrDefault("X-Amz-Algorithm")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "X-Amz-Algorithm", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-SignedHeaders", valid_607638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607640: Call_PutResourcePolicy_607628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_607640.validator(path, query, header, formData, body)
  let scheme = call_607640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607640.url(scheme.get, call_607640.host, call_607640.base,
                         call_607640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607640, url, valid)

proc call*(call_607641: Call_PutResourcePolicy_607628; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_607642 = newJObject()
  if body != nil:
    body_607642 = body
  result = call_607641.call(nil, nil, nil, nil, body_607642)

var putResourcePolicy* = Call_PutResourcePolicy_607628(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_607629, base: "/",
    url: url_PutResourcePolicy_607630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_607643 = ref object of OpenApiRestCall_605589
proc url_PutWorkflowRunProperties_607645(protocol: Scheme; host: string;
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

proc validate_PutWorkflowRunProperties_607644(path: JsonNode; query: JsonNode;
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
  var valid_607646 = header.getOrDefault("X-Amz-Target")
  valid_607646 = validateParameter(valid_607646, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_607646 != nil:
    section.add "X-Amz-Target", valid_607646
  var valid_607647 = header.getOrDefault("X-Amz-Signature")
  valid_607647 = validateParameter(valid_607647, JString, required = false,
                                 default = nil)
  if valid_607647 != nil:
    section.add "X-Amz-Signature", valid_607647
  var valid_607648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607648 = validateParameter(valid_607648, JString, required = false,
                                 default = nil)
  if valid_607648 != nil:
    section.add "X-Amz-Content-Sha256", valid_607648
  var valid_607649 = header.getOrDefault("X-Amz-Date")
  valid_607649 = validateParameter(valid_607649, JString, required = false,
                                 default = nil)
  if valid_607649 != nil:
    section.add "X-Amz-Date", valid_607649
  var valid_607650 = header.getOrDefault("X-Amz-Credential")
  valid_607650 = validateParameter(valid_607650, JString, required = false,
                                 default = nil)
  if valid_607650 != nil:
    section.add "X-Amz-Credential", valid_607650
  var valid_607651 = header.getOrDefault("X-Amz-Security-Token")
  valid_607651 = validateParameter(valid_607651, JString, required = false,
                                 default = nil)
  if valid_607651 != nil:
    section.add "X-Amz-Security-Token", valid_607651
  var valid_607652 = header.getOrDefault("X-Amz-Algorithm")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "X-Amz-Algorithm", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-SignedHeaders", valid_607653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607655: Call_PutWorkflowRunProperties_607643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_607655.validator(path, query, header, formData, body)
  let scheme = call_607655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607655.url(scheme.get, call_607655.host, call_607655.base,
                         call_607655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607655, url, valid)

proc call*(call_607656: Call_PutWorkflowRunProperties_607643; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_607657 = newJObject()
  if body != nil:
    body_607657 = body
  result = call_607656.call(nil, nil, nil, nil, body_607657)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_607643(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_607644, base: "/",
    url: url_PutWorkflowRunProperties_607645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_607658 = ref object of OpenApiRestCall_605589
proc url_ResetJobBookmark_607660(protocol: Scheme; host: string; base: string;
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

proc validate_ResetJobBookmark_607659(path: JsonNode; query: JsonNode;
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
  var valid_607661 = header.getOrDefault("X-Amz-Target")
  valid_607661 = validateParameter(valid_607661, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_607661 != nil:
    section.add "X-Amz-Target", valid_607661
  var valid_607662 = header.getOrDefault("X-Amz-Signature")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-Signature", valid_607662
  var valid_607663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607663 = validateParameter(valid_607663, JString, required = false,
                                 default = nil)
  if valid_607663 != nil:
    section.add "X-Amz-Content-Sha256", valid_607663
  var valid_607664 = header.getOrDefault("X-Amz-Date")
  valid_607664 = validateParameter(valid_607664, JString, required = false,
                                 default = nil)
  if valid_607664 != nil:
    section.add "X-Amz-Date", valid_607664
  var valid_607665 = header.getOrDefault("X-Amz-Credential")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-Credential", valid_607665
  var valid_607666 = header.getOrDefault("X-Amz-Security-Token")
  valid_607666 = validateParameter(valid_607666, JString, required = false,
                                 default = nil)
  if valid_607666 != nil:
    section.add "X-Amz-Security-Token", valid_607666
  var valid_607667 = header.getOrDefault("X-Amz-Algorithm")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "X-Amz-Algorithm", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-SignedHeaders", valid_607668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607670: Call_ResetJobBookmark_607658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_607670.validator(path, query, header, formData, body)
  let scheme = call_607670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607670.url(scheme.get, call_607670.host, call_607670.base,
                         call_607670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607670, url, valid)

proc call*(call_607671: Call_ResetJobBookmark_607658; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_607672 = newJObject()
  if body != nil:
    body_607672 = body
  result = call_607671.call(nil, nil, nil, nil, body_607672)

var resetJobBookmark* = Call_ResetJobBookmark_607658(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_607659, base: "/",
    url: url_ResetJobBookmark_607660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_607673 = ref object of OpenApiRestCall_605589
proc url_SearchTables_607675(protocol: Scheme; host: string; base: string;
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

proc validate_SearchTables_607674(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
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
  var valid_607676 = query.getOrDefault("MaxResults")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "MaxResults", valid_607676
  var valid_607677 = query.getOrDefault("NextToken")
  valid_607677 = validateParameter(valid_607677, JString, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "NextToken", valid_607677
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
  var valid_607678 = header.getOrDefault("X-Amz-Target")
  valid_607678 = validateParameter(valid_607678, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_607678 != nil:
    section.add "X-Amz-Target", valid_607678
  var valid_607679 = header.getOrDefault("X-Amz-Signature")
  valid_607679 = validateParameter(valid_607679, JString, required = false,
                                 default = nil)
  if valid_607679 != nil:
    section.add "X-Amz-Signature", valid_607679
  var valid_607680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607680 = validateParameter(valid_607680, JString, required = false,
                                 default = nil)
  if valid_607680 != nil:
    section.add "X-Amz-Content-Sha256", valid_607680
  var valid_607681 = header.getOrDefault("X-Amz-Date")
  valid_607681 = validateParameter(valid_607681, JString, required = false,
                                 default = nil)
  if valid_607681 != nil:
    section.add "X-Amz-Date", valid_607681
  var valid_607682 = header.getOrDefault("X-Amz-Credential")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "X-Amz-Credential", valid_607682
  var valid_607683 = header.getOrDefault("X-Amz-Security-Token")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "X-Amz-Security-Token", valid_607683
  var valid_607684 = header.getOrDefault("X-Amz-Algorithm")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "X-Amz-Algorithm", valid_607684
  var valid_607685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607685 = validateParameter(valid_607685, JString, required = false,
                                 default = nil)
  if valid_607685 != nil:
    section.add "X-Amz-SignedHeaders", valid_607685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607687: Call_SearchTables_607673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_607687.validator(path, query, header, formData, body)
  let scheme = call_607687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607687.url(scheme.get, call_607687.host, call_607687.base,
                         call_607687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607687, url, valid)

proc call*(call_607688: Call_SearchTables_607673; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607689 = newJObject()
  var body_607690 = newJObject()
  add(query_607689, "MaxResults", newJString(MaxResults))
  add(query_607689, "NextToken", newJString(NextToken))
  if body != nil:
    body_607690 = body
  result = call_607688.call(nil, query_607689, nil, nil, body_607690)

var searchTables* = Call_SearchTables_607673(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_607674, base: "/", url: url_SearchTables_607675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_607691 = ref object of OpenApiRestCall_605589
proc url_StartCrawler_607693(protocol: Scheme; host: string; base: string;
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

proc validate_StartCrawler_607692(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607694 = header.getOrDefault("X-Amz-Target")
  valid_607694 = validateParameter(valid_607694, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_607694 != nil:
    section.add "X-Amz-Target", valid_607694
  var valid_607695 = header.getOrDefault("X-Amz-Signature")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Signature", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Content-Sha256", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-Date")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Date", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Credential")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Credential", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Security-Token")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Security-Token", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Algorithm")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Algorithm", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-SignedHeaders", valid_607701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607703: Call_StartCrawler_607691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_607703.validator(path, query, header, formData, body)
  let scheme = call_607703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607703.url(scheme.get, call_607703.host, call_607703.base,
                         call_607703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607703, url, valid)

proc call*(call_607704: Call_StartCrawler_607691; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_607705 = newJObject()
  if body != nil:
    body_607705 = body
  result = call_607704.call(nil, nil, nil, nil, body_607705)

var startCrawler* = Call_StartCrawler_607691(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_607692, base: "/", url: url_StartCrawler_607693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_607706 = ref object of OpenApiRestCall_605589
proc url_StartCrawlerSchedule_607708(protocol: Scheme; host: string; base: string;
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

proc validate_StartCrawlerSchedule_607707(path: JsonNode; query: JsonNode;
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
  var valid_607709 = header.getOrDefault("X-Amz-Target")
  valid_607709 = validateParameter(valid_607709, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_607709 != nil:
    section.add "X-Amz-Target", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Signature")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Signature", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Content-Sha256", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Date")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Date", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Credential")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Credential", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Security-Token")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Security-Token", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-Algorithm")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-Algorithm", valid_607715
  var valid_607716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607716 = validateParameter(valid_607716, JString, required = false,
                                 default = nil)
  if valid_607716 != nil:
    section.add "X-Amz-SignedHeaders", valid_607716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607718: Call_StartCrawlerSchedule_607706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_607718.validator(path, query, header, formData, body)
  let scheme = call_607718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607718.url(scheme.get, call_607718.host, call_607718.base,
                         call_607718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607718, url, valid)

proc call*(call_607719: Call_StartCrawlerSchedule_607706; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_607720 = newJObject()
  if body != nil:
    body_607720 = body
  result = call_607719.call(nil, nil, nil, nil, body_607720)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_607706(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_607707, base: "/",
    url: url_StartCrawlerSchedule_607708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_607721 = ref object of OpenApiRestCall_605589
proc url_StartExportLabelsTaskRun_607723(protocol: Scheme; host: string;
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

proc validate_StartExportLabelsTaskRun_607722(path: JsonNode; query: JsonNode;
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
  var valid_607724 = header.getOrDefault("X-Amz-Target")
  valid_607724 = validateParameter(valid_607724, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_607724 != nil:
    section.add "X-Amz-Target", valid_607724
  var valid_607725 = header.getOrDefault("X-Amz-Signature")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "X-Amz-Signature", valid_607725
  var valid_607726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607726 = validateParameter(valid_607726, JString, required = false,
                                 default = nil)
  if valid_607726 != nil:
    section.add "X-Amz-Content-Sha256", valid_607726
  var valid_607727 = header.getOrDefault("X-Amz-Date")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "X-Amz-Date", valid_607727
  var valid_607728 = header.getOrDefault("X-Amz-Credential")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "X-Amz-Credential", valid_607728
  var valid_607729 = header.getOrDefault("X-Amz-Security-Token")
  valid_607729 = validateParameter(valid_607729, JString, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "X-Amz-Security-Token", valid_607729
  var valid_607730 = header.getOrDefault("X-Amz-Algorithm")
  valid_607730 = validateParameter(valid_607730, JString, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "X-Amz-Algorithm", valid_607730
  var valid_607731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607731 = validateParameter(valid_607731, JString, required = false,
                                 default = nil)
  if valid_607731 != nil:
    section.add "X-Amz-SignedHeaders", valid_607731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607733: Call_StartExportLabelsTaskRun_607721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_607733.validator(path, query, header, formData, body)
  let scheme = call_607733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607733.url(scheme.get, call_607733.host, call_607733.base,
                         call_607733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607733, url, valid)

proc call*(call_607734: Call_StartExportLabelsTaskRun_607721; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_607735 = newJObject()
  if body != nil:
    body_607735 = body
  result = call_607734.call(nil, nil, nil, nil, body_607735)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_607721(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_607722, base: "/",
    url: url_StartExportLabelsTaskRun_607723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_607736 = ref object of OpenApiRestCall_605589
proc url_StartImportLabelsTaskRun_607738(protocol: Scheme; host: string;
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

proc validate_StartImportLabelsTaskRun_607737(path: JsonNode; query: JsonNode;
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
  var valid_607739 = header.getOrDefault("X-Amz-Target")
  valid_607739 = validateParameter(valid_607739, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_607739 != nil:
    section.add "X-Amz-Target", valid_607739
  var valid_607740 = header.getOrDefault("X-Amz-Signature")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "X-Amz-Signature", valid_607740
  var valid_607741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Content-Sha256", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Date")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Date", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-Credential")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Credential", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-Security-Token")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-Security-Token", valid_607744
  var valid_607745 = header.getOrDefault("X-Amz-Algorithm")
  valid_607745 = validateParameter(valid_607745, JString, required = false,
                                 default = nil)
  if valid_607745 != nil:
    section.add "X-Amz-Algorithm", valid_607745
  var valid_607746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-SignedHeaders", valid_607746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607748: Call_StartImportLabelsTaskRun_607736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_607748.validator(path, query, header, formData, body)
  let scheme = call_607748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607748.url(scheme.get, call_607748.host, call_607748.base,
                         call_607748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607748, url, valid)

proc call*(call_607749: Call_StartImportLabelsTaskRun_607736; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_607750 = newJObject()
  if body != nil:
    body_607750 = body
  result = call_607749.call(nil, nil, nil, nil, body_607750)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_607736(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_607737, base: "/",
    url: url_StartImportLabelsTaskRun_607738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_607751 = ref object of OpenApiRestCall_605589
proc url_StartJobRun_607753(protocol: Scheme; host: string; base: string;
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

proc validate_StartJobRun_607752(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607754 = header.getOrDefault("X-Amz-Target")
  valid_607754 = validateParameter(valid_607754, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_607754 != nil:
    section.add "X-Amz-Target", valid_607754
  var valid_607755 = header.getOrDefault("X-Amz-Signature")
  valid_607755 = validateParameter(valid_607755, JString, required = false,
                                 default = nil)
  if valid_607755 != nil:
    section.add "X-Amz-Signature", valid_607755
  var valid_607756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Content-Sha256", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-Date")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-Date", valid_607757
  var valid_607758 = header.getOrDefault("X-Amz-Credential")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Credential", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-Security-Token")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-Security-Token", valid_607759
  var valid_607760 = header.getOrDefault("X-Amz-Algorithm")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "X-Amz-Algorithm", valid_607760
  var valid_607761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607761 = validateParameter(valid_607761, JString, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "X-Amz-SignedHeaders", valid_607761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607763: Call_StartJobRun_607751; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_607763.validator(path, query, header, formData, body)
  let scheme = call_607763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607763.url(scheme.get, call_607763.host, call_607763.base,
                         call_607763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607763, url, valid)

proc call*(call_607764: Call_StartJobRun_607751; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_607765 = newJObject()
  if body != nil:
    body_607765 = body
  result = call_607764.call(nil, nil, nil, nil, body_607765)

var startJobRun* = Call_StartJobRun_607751(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_607752,
                                        base: "/", url: url_StartJobRun_607753,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_607766 = ref object of OpenApiRestCall_605589
proc url_StartMLEvaluationTaskRun_607768(protocol: Scheme; host: string;
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

proc validate_StartMLEvaluationTaskRun_607767(path: JsonNode; query: JsonNode;
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
  var valid_607769 = header.getOrDefault("X-Amz-Target")
  valid_607769 = validateParameter(valid_607769, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_607769 != nil:
    section.add "X-Amz-Target", valid_607769
  var valid_607770 = header.getOrDefault("X-Amz-Signature")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "X-Amz-Signature", valid_607770
  var valid_607771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "X-Amz-Content-Sha256", valid_607771
  var valid_607772 = header.getOrDefault("X-Amz-Date")
  valid_607772 = validateParameter(valid_607772, JString, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "X-Amz-Date", valid_607772
  var valid_607773 = header.getOrDefault("X-Amz-Credential")
  valid_607773 = validateParameter(valid_607773, JString, required = false,
                                 default = nil)
  if valid_607773 != nil:
    section.add "X-Amz-Credential", valid_607773
  var valid_607774 = header.getOrDefault("X-Amz-Security-Token")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-Security-Token", valid_607774
  var valid_607775 = header.getOrDefault("X-Amz-Algorithm")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "X-Amz-Algorithm", valid_607775
  var valid_607776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607776 = validateParameter(valid_607776, JString, required = false,
                                 default = nil)
  if valid_607776 != nil:
    section.add "X-Amz-SignedHeaders", valid_607776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607778: Call_StartMLEvaluationTaskRun_607766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_607778.validator(path, query, header, formData, body)
  let scheme = call_607778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607778.url(scheme.get, call_607778.host, call_607778.base,
                         call_607778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607778, url, valid)

proc call*(call_607779: Call_StartMLEvaluationTaskRun_607766; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_607780 = newJObject()
  if body != nil:
    body_607780 = body
  result = call_607779.call(nil, nil, nil, nil, body_607780)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_607766(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_607767, base: "/",
    url: url_StartMLEvaluationTaskRun_607768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_607781 = ref object of OpenApiRestCall_605589
proc url_StartMLLabelingSetGenerationTaskRun_607783(protocol: Scheme; host: string;
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

proc validate_StartMLLabelingSetGenerationTaskRun_607782(path: JsonNode;
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
  var valid_607784 = header.getOrDefault("X-Amz-Target")
  valid_607784 = validateParameter(valid_607784, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_607784 != nil:
    section.add "X-Amz-Target", valid_607784
  var valid_607785 = header.getOrDefault("X-Amz-Signature")
  valid_607785 = validateParameter(valid_607785, JString, required = false,
                                 default = nil)
  if valid_607785 != nil:
    section.add "X-Amz-Signature", valid_607785
  var valid_607786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Content-Sha256", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-Date")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-Date", valid_607787
  var valid_607788 = header.getOrDefault("X-Amz-Credential")
  valid_607788 = validateParameter(valid_607788, JString, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "X-Amz-Credential", valid_607788
  var valid_607789 = header.getOrDefault("X-Amz-Security-Token")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-Security-Token", valid_607789
  var valid_607790 = header.getOrDefault("X-Amz-Algorithm")
  valid_607790 = validateParameter(valid_607790, JString, required = false,
                                 default = nil)
  if valid_607790 != nil:
    section.add "X-Amz-Algorithm", valid_607790
  var valid_607791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607791 = validateParameter(valid_607791, JString, required = false,
                                 default = nil)
  if valid_607791 != nil:
    section.add "X-Amz-SignedHeaders", valid_607791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607793: Call_StartMLLabelingSetGenerationTaskRun_607781;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_607793.validator(path, query, header, formData, body)
  let scheme = call_607793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607793.url(scheme.get, call_607793.host, call_607793.base,
                         call_607793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607793, url, valid)

proc call*(call_607794: Call_StartMLLabelingSetGenerationTaskRun_607781;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_607795 = newJObject()
  if body != nil:
    body_607795 = body
  result = call_607794.call(nil, nil, nil, nil, body_607795)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_607781(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_607782, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_607783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_607796 = ref object of OpenApiRestCall_605589
proc url_StartTrigger_607798(protocol: Scheme; host: string; base: string;
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

proc validate_StartTrigger_607797(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607799 = header.getOrDefault("X-Amz-Target")
  valid_607799 = validateParameter(valid_607799, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_607799 != nil:
    section.add "X-Amz-Target", valid_607799
  var valid_607800 = header.getOrDefault("X-Amz-Signature")
  valid_607800 = validateParameter(valid_607800, JString, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "X-Amz-Signature", valid_607800
  var valid_607801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607801 = validateParameter(valid_607801, JString, required = false,
                                 default = nil)
  if valid_607801 != nil:
    section.add "X-Amz-Content-Sha256", valid_607801
  var valid_607802 = header.getOrDefault("X-Amz-Date")
  valid_607802 = validateParameter(valid_607802, JString, required = false,
                                 default = nil)
  if valid_607802 != nil:
    section.add "X-Amz-Date", valid_607802
  var valid_607803 = header.getOrDefault("X-Amz-Credential")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Credential", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-Security-Token")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-Security-Token", valid_607804
  var valid_607805 = header.getOrDefault("X-Amz-Algorithm")
  valid_607805 = validateParameter(valid_607805, JString, required = false,
                                 default = nil)
  if valid_607805 != nil:
    section.add "X-Amz-Algorithm", valid_607805
  var valid_607806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607806 = validateParameter(valid_607806, JString, required = false,
                                 default = nil)
  if valid_607806 != nil:
    section.add "X-Amz-SignedHeaders", valid_607806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607808: Call_StartTrigger_607796; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_607808.validator(path, query, header, formData, body)
  let scheme = call_607808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607808.url(scheme.get, call_607808.host, call_607808.base,
                         call_607808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607808, url, valid)

proc call*(call_607809: Call_StartTrigger_607796; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_607810 = newJObject()
  if body != nil:
    body_607810 = body
  result = call_607809.call(nil, nil, nil, nil, body_607810)

var startTrigger* = Call_StartTrigger_607796(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_607797, base: "/", url: url_StartTrigger_607798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_607811 = ref object of OpenApiRestCall_605589
proc url_StartWorkflowRun_607813(protocol: Scheme; host: string; base: string;
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

proc validate_StartWorkflowRun_607812(path: JsonNode; query: JsonNode;
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
  var valid_607814 = header.getOrDefault("X-Amz-Target")
  valid_607814 = validateParameter(valid_607814, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_607814 != nil:
    section.add "X-Amz-Target", valid_607814
  var valid_607815 = header.getOrDefault("X-Amz-Signature")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-Signature", valid_607815
  var valid_607816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = nil)
  if valid_607816 != nil:
    section.add "X-Amz-Content-Sha256", valid_607816
  var valid_607817 = header.getOrDefault("X-Amz-Date")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "X-Amz-Date", valid_607817
  var valid_607818 = header.getOrDefault("X-Amz-Credential")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Credential", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-Security-Token")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-Security-Token", valid_607819
  var valid_607820 = header.getOrDefault("X-Amz-Algorithm")
  valid_607820 = validateParameter(valid_607820, JString, required = false,
                                 default = nil)
  if valid_607820 != nil:
    section.add "X-Amz-Algorithm", valid_607820
  var valid_607821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607821 = validateParameter(valid_607821, JString, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "X-Amz-SignedHeaders", valid_607821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607823: Call_StartWorkflowRun_607811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_607823.validator(path, query, header, formData, body)
  let scheme = call_607823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607823.url(scheme.get, call_607823.host, call_607823.base,
                         call_607823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607823, url, valid)

proc call*(call_607824: Call_StartWorkflowRun_607811; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_607825 = newJObject()
  if body != nil:
    body_607825 = body
  result = call_607824.call(nil, nil, nil, nil, body_607825)

var startWorkflowRun* = Call_StartWorkflowRun_607811(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_607812, base: "/",
    url: url_StartWorkflowRun_607813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_607826 = ref object of OpenApiRestCall_605589
proc url_StopCrawler_607828(protocol: Scheme; host: string; base: string;
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

proc validate_StopCrawler_607827(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607829 = header.getOrDefault("X-Amz-Target")
  valid_607829 = validateParameter(valid_607829, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_607829 != nil:
    section.add "X-Amz-Target", valid_607829
  var valid_607830 = header.getOrDefault("X-Amz-Signature")
  valid_607830 = validateParameter(valid_607830, JString, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "X-Amz-Signature", valid_607830
  var valid_607831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607831 = validateParameter(valid_607831, JString, required = false,
                                 default = nil)
  if valid_607831 != nil:
    section.add "X-Amz-Content-Sha256", valid_607831
  var valid_607832 = header.getOrDefault("X-Amz-Date")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "X-Amz-Date", valid_607832
  var valid_607833 = header.getOrDefault("X-Amz-Credential")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "X-Amz-Credential", valid_607833
  var valid_607834 = header.getOrDefault("X-Amz-Security-Token")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-Security-Token", valid_607834
  var valid_607835 = header.getOrDefault("X-Amz-Algorithm")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Algorithm", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-SignedHeaders", valid_607836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607838: Call_StopCrawler_607826; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_607838.validator(path, query, header, formData, body)
  let scheme = call_607838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607838.url(scheme.get, call_607838.host, call_607838.base,
                         call_607838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607838, url, valid)

proc call*(call_607839: Call_StopCrawler_607826; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_607840 = newJObject()
  if body != nil:
    body_607840 = body
  result = call_607839.call(nil, nil, nil, nil, body_607840)

var stopCrawler* = Call_StopCrawler_607826(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_607827,
                                        base: "/", url: url_StopCrawler_607828,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_607841 = ref object of OpenApiRestCall_605589
proc url_StopCrawlerSchedule_607843(protocol: Scheme; host: string; base: string;
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

proc validate_StopCrawlerSchedule_607842(path: JsonNode; query: JsonNode;
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
  var valid_607844 = header.getOrDefault("X-Amz-Target")
  valid_607844 = validateParameter(valid_607844, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_607844 != nil:
    section.add "X-Amz-Target", valid_607844
  var valid_607845 = header.getOrDefault("X-Amz-Signature")
  valid_607845 = validateParameter(valid_607845, JString, required = false,
                                 default = nil)
  if valid_607845 != nil:
    section.add "X-Amz-Signature", valid_607845
  var valid_607846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607846 = validateParameter(valid_607846, JString, required = false,
                                 default = nil)
  if valid_607846 != nil:
    section.add "X-Amz-Content-Sha256", valid_607846
  var valid_607847 = header.getOrDefault("X-Amz-Date")
  valid_607847 = validateParameter(valid_607847, JString, required = false,
                                 default = nil)
  if valid_607847 != nil:
    section.add "X-Amz-Date", valid_607847
  var valid_607848 = header.getOrDefault("X-Amz-Credential")
  valid_607848 = validateParameter(valid_607848, JString, required = false,
                                 default = nil)
  if valid_607848 != nil:
    section.add "X-Amz-Credential", valid_607848
  var valid_607849 = header.getOrDefault("X-Amz-Security-Token")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-Security-Token", valid_607849
  var valid_607850 = header.getOrDefault("X-Amz-Algorithm")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "X-Amz-Algorithm", valid_607850
  var valid_607851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-SignedHeaders", valid_607851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607853: Call_StopCrawlerSchedule_607841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_607853.validator(path, query, header, formData, body)
  let scheme = call_607853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607853.url(scheme.get, call_607853.host, call_607853.base,
                         call_607853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607853, url, valid)

proc call*(call_607854: Call_StopCrawlerSchedule_607841; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_607855 = newJObject()
  if body != nil:
    body_607855 = body
  result = call_607854.call(nil, nil, nil, nil, body_607855)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_607841(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_607842, base: "/",
    url: url_StopCrawlerSchedule_607843, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_607856 = ref object of OpenApiRestCall_605589
proc url_StopTrigger_607858(protocol: Scheme; host: string; base: string;
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

proc validate_StopTrigger_607857(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607859 = header.getOrDefault("X-Amz-Target")
  valid_607859 = validateParameter(valid_607859, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_607859 != nil:
    section.add "X-Amz-Target", valid_607859
  var valid_607860 = header.getOrDefault("X-Amz-Signature")
  valid_607860 = validateParameter(valid_607860, JString, required = false,
                                 default = nil)
  if valid_607860 != nil:
    section.add "X-Amz-Signature", valid_607860
  var valid_607861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607861 = validateParameter(valid_607861, JString, required = false,
                                 default = nil)
  if valid_607861 != nil:
    section.add "X-Amz-Content-Sha256", valid_607861
  var valid_607862 = header.getOrDefault("X-Amz-Date")
  valid_607862 = validateParameter(valid_607862, JString, required = false,
                                 default = nil)
  if valid_607862 != nil:
    section.add "X-Amz-Date", valid_607862
  var valid_607863 = header.getOrDefault("X-Amz-Credential")
  valid_607863 = validateParameter(valid_607863, JString, required = false,
                                 default = nil)
  if valid_607863 != nil:
    section.add "X-Amz-Credential", valid_607863
  var valid_607864 = header.getOrDefault("X-Amz-Security-Token")
  valid_607864 = validateParameter(valid_607864, JString, required = false,
                                 default = nil)
  if valid_607864 != nil:
    section.add "X-Amz-Security-Token", valid_607864
  var valid_607865 = header.getOrDefault("X-Amz-Algorithm")
  valid_607865 = validateParameter(valid_607865, JString, required = false,
                                 default = nil)
  if valid_607865 != nil:
    section.add "X-Amz-Algorithm", valid_607865
  var valid_607866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607866 = validateParameter(valid_607866, JString, required = false,
                                 default = nil)
  if valid_607866 != nil:
    section.add "X-Amz-SignedHeaders", valid_607866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607868: Call_StopTrigger_607856; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_607868.validator(path, query, header, formData, body)
  let scheme = call_607868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607868.url(scheme.get, call_607868.host, call_607868.base,
                         call_607868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607868, url, valid)

proc call*(call_607869: Call_StopTrigger_607856; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_607870 = newJObject()
  if body != nil:
    body_607870 = body
  result = call_607869.call(nil, nil, nil, nil, body_607870)

var stopTrigger* = Call_StopTrigger_607856(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_607857,
                                        base: "/", url: url_StopTrigger_607858,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607871 = ref object of OpenApiRestCall_605589
proc url_TagResource_607873(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607872(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607874 = header.getOrDefault("X-Amz-Target")
  valid_607874 = validateParameter(valid_607874, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_607874 != nil:
    section.add "X-Amz-Target", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-Signature")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-Signature", valid_607875
  var valid_607876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607876 = validateParameter(valid_607876, JString, required = false,
                                 default = nil)
  if valid_607876 != nil:
    section.add "X-Amz-Content-Sha256", valid_607876
  var valid_607877 = header.getOrDefault("X-Amz-Date")
  valid_607877 = validateParameter(valid_607877, JString, required = false,
                                 default = nil)
  if valid_607877 != nil:
    section.add "X-Amz-Date", valid_607877
  var valid_607878 = header.getOrDefault("X-Amz-Credential")
  valid_607878 = validateParameter(valid_607878, JString, required = false,
                                 default = nil)
  if valid_607878 != nil:
    section.add "X-Amz-Credential", valid_607878
  var valid_607879 = header.getOrDefault("X-Amz-Security-Token")
  valid_607879 = validateParameter(valid_607879, JString, required = false,
                                 default = nil)
  if valid_607879 != nil:
    section.add "X-Amz-Security-Token", valid_607879
  var valid_607880 = header.getOrDefault("X-Amz-Algorithm")
  valid_607880 = validateParameter(valid_607880, JString, required = false,
                                 default = nil)
  if valid_607880 != nil:
    section.add "X-Amz-Algorithm", valid_607880
  var valid_607881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607881 = validateParameter(valid_607881, JString, required = false,
                                 default = nil)
  if valid_607881 != nil:
    section.add "X-Amz-SignedHeaders", valid_607881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607883: Call_TagResource_607871; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_607883.validator(path, query, header, formData, body)
  let scheme = call_607883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607883.url(scheme.get, call_607883.host, call_607883.base,
                         call_607883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607883, url, valid)

proc call*(call_607884: Call_TagResource_607871; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_607885 = newJObject()
  if body != nil:
    body_607885 = body
  result = call_607884.call(nil, nil, nil, nil, body_607885)

var tagResource* = Call_TagResource_607871(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_607872,
                                        base: "/", url: url_TagResource_607873,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607886 = ref object of OpenApiRestCall_605589
proc url_UntagResource_607888(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607889 = header.getOrDefault("X-Amz-Target")
  valid_607889 = validateParameter(valid_607889, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_607889 != nil:
    section.add "X-Amz-Target", valid_607889
  var valid_607890 = header.getOrDefault("X-Amz-Signature")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "X-Amz-Signature", valid_607890
  var valid_607891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "X-Amz-Content-Sha256", valid_607891
  var valid_607892 = header.getOrDefault("X-Amz-Date")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-Date", valid_607892
  var valid_607893 = header.getOrDefault("X-Amz-Credential")
  valid_607893 = validateParameter(valid_607893, JString, required = false,
                                 default = nil)
  if valid_607893 != nil:
    section.add "X-Amz-Credential", valid_607893
  var valid_607894 = header.getOrDefault("X-Amz-Security-Token")
  valid_607894 = validateParameter(valid_607894, JString, required = false,
                                 default = nil)
  if valid_607894 != nil:
    section.add "X-Amz-Security-Token", valid_607894
  var valid_607895 = header.getOrDefault("X-Amz-Algorithm")
  valid_607895 = validateParameter(valid_607895, JString, required = false,
                                 default = nil)
  if valid_607895 != nil:
    section.add "X-Amz-Algorithm", valid_607895
  var valid_607896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607896 = validateParameter(valid_607896, JString, required = false,
                                 default = nil)
  if valid_607896 != nil:
    section.add "X-Amz-SignedHeaders", valid_607896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607898: Call_UntagResource_607886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_607898.validator(path, query, header, formData, body)
  let scheme = call_607898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607898.url(scheme.get, call_607898.host, call_607898.base,
                         call_607898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607898, url, valid)

proc call*(call_607899: Call_UntagResource_607886; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_607900 = newJObject()
  if body != nil:
    body_607900 = body
  result = call_607899.call(nil, nil, nil, nil, body_607900)

var untagResource* = Call_UntagResource_607886(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_607887, base: "/", url: url_UntagResource_607888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_607901 = ref object of OpenApiRestCall_605589
proc url_UpdateClassifier_607903(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClassifier_607902(path: JsonNode; query: JsonNode;
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
  var valid_607904 = header.getOrDefault("X-Amz-Target")
  valid_607904 = validateParameter(valid_607904, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_607904 != nil:
    section.add "X-Amz-Target", valid_607904
  var valid_607905 = header.getOrDefault("X-Amz-Signature")
  valid_607905 = validateParameter(valid_607905, JString, required = false,
                                 default = nil)
  if valid_607905 != nil:
    section.add "X-Amz-Signature", valid_607905
  var valid_607906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607906 = validateParameter(valid_607906, JString, required = false,
                                 default = nil)
  if valid_607906 != nil:
    section.add "X-Amz-Content-Sha256", valid_607906
  var valid_607907 = header.getOrDefault("X-Amz-Date")
  valid_607907 = validateParameter(valid_607907, JString, required = false,
                                 default = nil)
  if valid_607907 != nil:
    section.add "X-Amz-Date", valid_607907
  var valid_607908 = header.getOrDefault("X-Amz-Credential")
  valid_607908 = validateParameter(valid_607908, JString, required = false,
                                 default = nil)
  if valid_607908 != nil:
    section.add "X-Amz-Credential", valid_607908
  var valid_607909 = header.getOrDefault("X-Amz-Security-Token")
  valid_607909 = validateParameter(valid_607909, JString, required = false,
                                 default = nil)
  if valid_607909 != nil:
    section.add "X-Amz-Security-Token", valid_607909
  var valid_607910 = header.getOrDefault("X-Amz-Algorithm")
  valid_607910 = validateParameter(valid_607910, JString, required = false,
                                 default = nil)
  if valid_607910 != nil:
    section.add "X-Amz-Algorithm", valid_607910
  var valid_607911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607911 = validateParameter(valid_607911, JString, required = false,
                                 default = nil)
  if valid_607911 != nil:
    section.add "X-Amz-SignedHeaders", valid_607911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607913: Call_UpdateClassifier_607901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_607913.validator(path, query, header, formData, body)
  let scheme = call_607913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607913.url(scheme.get, call_607913.host, call_607913.base,
                         call_607913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607913, url, valid)

proc call*(call_607914: Call_UpdateClassifier_607901; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_607915 = newJObject()
  if body != nil:
    body_607915 = body
  result = call_607914.call(nil, nil, nil, nil, body_607915)

var updateClassifier* = Call_UpdateClassifier_607901(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_607902, base: "/",
    url: url_UpdateClassifier_607903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_607916 = ref object of OpenApiRestCall_605589
proc url_UpdateConnection_607918(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnection_607917(path: JsonNode; query: JsonNode;
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
  var valid_607919 = header.getOrDefault("X-Amz-Target")
  valid_607919 = validateParameter(valid_607919, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_607919 != nil:
    section.add "X-Amz-Target", valid_607919
  var valid_607920 = header.getOrDefault("X-Amz-Signature")
  valid_607920 = validateParameter(valid_607920, JString, required = false,
                                 default = nil)
  if valid_607920 != nil:
    section.add "X-Amz-Signature", valid_607920
  var valid_607921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607921 = validateParameter(valid_607921, JString, required = false,
                                 default = nil)
  if valid_607921 != nil:
    section.add "X-Amz-Content-Sha256", valid_607921
  var valid_607922 = header.getOrDefault("X-Amz-Date")
  valid_607922 = validateParameter(valid_607922, JString, required = false,
                                 default = nil)
  if valid_607922 != nil:
    section.add "X-Amz-Date", valid_607922
  var valid_607923 = header.getOrDefault("X-Amz-Credential")
  valid_607923 = validateParameter(valid_607923, JString, required = false,
                                 default = nil)
  if valid_607923 != nil:
    section.add "X-Amz-Credential", valid_607923
  var valid_607924 = header.getOrDefault("X-Amz-Security-Token")
  valid_607924 = validateParameter(valid_607924, JString, required = false,
                                 default = nil)
  if valid_607924 != nil:
    section.add "X-Amz-Security-Token", valid_607924
  var valid_607925 = header.getOrDefault("X-Amz-Algorithm")
  valid_607925 = validateParameter(valid_607925, JString, required = false,
                                 default = nil)
  if valid_607925 != nil:
    section.add "X-Amz-Algorithm", valid_607925
  var valid_607926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607926 = validateParameter(valid_607926, JString, required = false,
                                 default = nil)
  if valid_607926 != nil:
    section.add "X-Amz-SignedHeaders", valid_607926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607928: Call_UpdateConnection_607916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_607928.validator(path, query, header, formData, body)
  let scheme = call_607928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607928.url(scheme.get, call_607928.host, call_607928.base,
                         call_607928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607928, url, valid)

proc call*(call_607929: Call_UpdateConnection_607916; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_607930 = newJObject()
  if body != nil:
    body_607930 = body
  result = call_607929.call(nil, nil, nil, nil, body_607930)

var updateConnection* = Call_UpdateConnection_607916(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_607917, base: "/",
    url: url_UpdateConnection_607918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_607931 = ref object of OpenApiRestCall_605589
proc url_UpdateCrawler_607933(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCrawler_607932(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607934 = header.getOrDefault("X-Amz-Target")
  valid_607934 = validateParameter(valid_607934, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_607934 != nil:
    section.add "X-Amz-Target", valid_607934
  var valid_607935 = header.getOrDefault("X-Amz-Signature")
  valid_607935 = validateParameter(valid_607935, JString, required = false,
                                 default = nil)
  if valid_607935 != nil:
    section.add "X-Amz-Signature", valid_607935
  var valid_607936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607936 = validateParameter(valid_607936, JString, required = false,
                                 default = nil)
  if valid_607936 != nil:
    section.add "X-Amz-Content-Sha256", valid_607936
  var valid_607937 = header.getOrDefault("X-Amz-Date")
  valid_607937 = validateParameter(valid_607937, JString, required = false,
                                 default = nil)
  if valid_607937 != nil:
    section.add "X-Amz-Date", valid_607937
  var valid_607938 = header.getOrDefault("X-Amz-Credential")
  valid_607938 = validateParameter(valid_607938, JString, required = false,
                                 default = nil)
  if valid_607938 != nil:
    section.add "X-Amz-Credential", valid_607938
  var valid_607939 = header.getOrDefault("X-Amz-Security-Token")
  valid_607939 = validateParameter(valid_607939, JString, required = false,
                                 default = nil)
  if valid_607939 != nil:
    section.add "X-Amz-Security-Token", valid_607939
  var valid_607940 = header.getOrDefault("X-Amz-Algorithm")
  valid_607940 = validateParameter(valid_607940, JString, required = false,
                                 default = nil)
  if valid_607940 != nil:
    section.add "X-Amz-Algorithm", valid_607940
  var valid_607941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607941 = validateParameter(valid_607941, JString, required = false,
                                 default = nil)
  if valid_607941 != nil:
    section.add "X-Amz-SignedHeaders", valid_607941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607943: Call_UpdateCrawler_607931; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_607943.validator(path, query, header, formData, body)
  let scheme = call_607943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607943.url(scheme.get, call_607943.host, call_607943.base,
                         call_607943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607943, url, valid)

proc call*(call_607944: Call_UpdateCrawler_607931; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_607945 = newJObject()
  if body != nil:
    body_607945 = body
  result = call_607944.call(nil, nil, nil, nil, body_607945)

var updateCrawler* = Call_UpdateCrawler_607931(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_607932, base: "/", url: url_UpdateCrawler_607933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_607946 = ref object of OpenApiRestCall_605589
proc url_UpdateCrawlerSchedule_607948(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCrawlerSchedule_607947(path: JsonNode; query: JsonNode;
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
  var valid_607949 = header.getOrDefault("X-Amz-Target")
  valid_607949 = validateParameter(valid_607949, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_607949 != nil:
    section.add "X-Amz-Target", valid_607949
  var valid_607950 = header.getOrDefault("X-Amz-Signature")
  valid_607950 = validateParameter(valid_607950, JString, required = false,
                                 default = nil)
  if valid_607950 != nil:
    section.add "X-Amz-Signature", valid_607950
  var valid_607951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607951 = validateParameter(valid_607951, JString, required = false,
                                 default = nil)
  if valid_607951 != nil:
    section.add "X-Amz-Content-Sha256", valid_607951
  var valid_607952 = header.getOrDefault("X-Amz-Date")
  valid_607952 = validateParameter(valid_607952, JString, required = false,
                                 default = nil)
  if valid_607952 != nil:
    section.add "X-Amz-Date", valid_607952
  var valid_607953 = header.getOrDefault("X-Amz-Credential")
  valid_607953 = validateParameter(valid_607953, JString, required = false,
                                 default = nil)
  if valid_607953 != nil:
    section.add "X-Amz-Credential", valid_607953
  var valid_607954 = header.getOrDefault("X-Amz-Security-Token")
  valid_607954 = validateParameter(valid_607954, JString, required = false,
                                 default = nil)
  if valid_607954 != nil:
    section.add "X-Amz-Security-Token", valid_607954
  var valid_607955 = header.getOrDefault("X-Amz-Algorithm")
  valid_607955 = validateParameter(valid_607955, JString, required = false,
                                 default = nil)
  if valid_607955 != nil:
    section.add "X-Amz-Algorithm", valid_607955
  var valid_607956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607956 = validateParameter(valid_607956, JString, required = false,
                                 default = nil)
  if valid_607956 != nil:
    section.add "X-Amz-SignedHeaders", valid_607956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607958: Call_UpdateCrawlerSchedule_607946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_607958.validator(path, query, header, formData, body)
  let scheme = call_607958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607958.url(scheme.get, call_607958.host, call_607958.base,
                         call_607958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607958, url, valid)

proc call*(call_607959: Call_UpdateCrawlerSchedule_607946; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_607960 = newJObject()
  if body != nil:
    body_607960 = body
  result = call_607959.call(nil, nil, nil, nil, body_607960)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_607946(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_607947, base: "/",
    url: url_UpdateCrawlerSchedule_607948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_607961 = ref object of OpenApiRestCall_605589
proc url_UpdateDatabase_607963(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDatabase_607962(path: JsonNode; query: JsonNode;
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
  var valid_607964 = header.getOrDefault("X-Amz-Target")
  valid_607964 = validateParameter(valid_607964, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_607964 != nil:
    section.add "X-Amz-Target", valid_607964
  var valid_607965 = header.getOrDefault("X-Amz-Signature")
  valid_607965 = validateParameter(valid_607965, JString, required = false,
                                 default = nil)
  if valid_607965 != nil:
    section.add "X-Amz-Signature", valid_607965
  var valid_607966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607966 = validateParameter(valid_607966, JString, required = false,
                                 default = nil)
  if valid_607966 != nil:
    section.add "X-Amz-Content-Sha256", valid_607966
  var valid_607967 = header.getOrDefault("X-Amz-Date")
  valid_607967 = validateParameter(valid_607967, JString, required = false,
                                 default = nil)
  if valid_607967 != nil:
    section.add "X-Amz-Date", valid_607967
  var valid_607968 = header.getOrDefault("X-Amz-Credential")
  valid_607968 = validateParameter(valid_607968, JString, required = false,
                                 default = nil)
  if valid_607968 != nil:
    section.add "X-Amz-Credential", valid_607968
  var valid_607969 = header.getOrDefault("X-Amz-Security-Token")
  valid_607969 = validateParameter(valid_607969, JString, required = false,
                                 default = nil)
  if valid_607969 != nil:
    section.add "X-Amz-Security-Token", valid_607969
  var valid_607970 = header.getOrDefault("X-Amz-Algorithm")
  valid_607970 = validateParameter(valid_607970, JString, required = false,
                                 default = nil)
  if valid_607970 != nil:
    section.add "X-Amz-Algorithm", valid_607970
  var valid_607971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607971 = validateParameter(valid_607971, JString, required = false,
                                 default = nil)
  if valid_607971 != nil:
    section.add "X-Amz-SignedHeaders", valid_607971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607973: Call_UpdateDatabase_607961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_607973.validator(path, query, header, formData, body)
  let scheme = call_607973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607973.url(scheme.get, call_607973.host, call_607973.base,
                         call_607973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607973, url, valid)

proc call*(call_607974: Call_UpdateDatabase_607961; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_607975 = newJObject()
  if body != nil:
    body_607975 = body
  result = call_607974.call(nil, nil, nil, nil, body_607975)

var updateDatabase* = Call_UpdateDatabase_607961(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_607962, base: "/", url: url_UpdateDatabase_607963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_607976 = ref object of OpenApiRestCall_605589
proc url_UpdateDevEndpoint_607978(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevEndpoint_607977(path: JsonNode; query: JsonNode;
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
  var valid_607979 = header.getOrDefault("X-Amz-Target")
  valid_607979 = validateParameter(valid_607979, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_607979 != nil:
    section.add "X-Amz-Target", valid_607979
  var valid_607980 = header.getOrDefault("X-Amz-Signature")
  valid_607980 = validateParameter(valid_607980, JString, required = false,
                                 default = nil)
  if valid_607980 != nil:
    section.add "X-Amz-Signature", valid_607980
  var valid_607981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607981 = validateParameter(valid_607981, JString, required = false,
                                 default = nil)
  if valid_607981 != nil:
    section.add "X-Amz-Content-Sha256", valid_607981
  var valid_607982 = header.getOrDefault("X-Amz-Date")
  valid_607982 = validateParameter(valid_607982, JString, required = false,
                                 default = nil)
  if valid_607982 != nil:
    section.add "X-Amz-Date", valid_607982
  var valid_607983 = header.getOrDefault("X-Amz-Credential")
  valid_607983 = validateParameter(valid_607983, JString, required = false,
                                 default = nil)
  if valid_607983 != nil:
    section.add "X-Amz-Credential", valid_607983
  var valid_607984 = header.getOrDefault("X-Amz-Security-Token")
  valid_607984 = validateParameter(valid_607984, JString, required = false,
                                 default = nil)
  if valid_607984 != nil:
    section.add "X-Amz-Security-Token", valid_607984
  var valid_607985 = header.getOrDefault("X-Amz-Algorithm")
  valid_607985 = validateParameter(valid_607985, JString, required = false,
                                 default = nil)
  if valid_607985 != nil:
    section.add "X-Amz-Algorithm", valid_607985
  var valid_607986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607986 = validateParameter(valid_607986, JString, required = false,
                                 default = nil)
  if valid_607986 != nil:
    section.add "X-Amz-SignedHeaders", valid_607986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607988: Call_UpdateDevEndpoint_607976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_607988.validator(path, query, header, formData, body)
  let scheme = call_607988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607988.url(scheme.get, call_607988.host, call_607988.base,
                         call_607988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607988, url, valid)

proc call*(call_607989: Call_UpdateDevEndpoint_607976; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_607990 = newJObject()
  if body != nil:
    body_607990 = body
  result = call_607989.call(nil, nil, nil, nil, body_607990)

var updateDevEndpoint* = Call_UpdateDevEndpoint_607976(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_607977, base: "/",
    url: url_UpdateDevEndpoint_607978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_607991 = ref object of OpenApiRestCall_605589
proc url_UpdateJob_607993(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateJob_607992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607994 = header.getOrDefault("X-Amz-Target")
  valid_607994 = validateParameter(valid_607994, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_607994 != nil:
    section.add "X-Amz-Target", valid_607994
  var valid_607995 = header.getOrDefault("X-Amz-Signature")
  valid_607995 = validateParameter(valid_607995, JString, required = false,
                                 default = nil)
  if valid_607995 != nil:
    section.add "X-Amz-Signature", valid_607995
  var valid_607996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607996 = validateParameter(valid_607996, JString, required = false,
                                 default = nil)
  if valid_607996 != nil:
    section.add "X-Amz-Content-Sha256", valid_607996
  var valid_607997 = header.getOrDefault("X-Amz-Date")
  valid_607997 = validateParameter(valid_607997, JString, required = false,
                                 default = nil)
  if valid_607997 != nil:
    section.add "X-Amz-Date", valid_607997
  var valid_607998 = header.getOrDefault("X-Amz-Credential")
  valid_607998 = validateParameter(valid_607998, JString, required = false,
                                 default = nil)
  if valid_607998 != nil:
    section.add "X-Amz-Credential", valid_607998
  var valid_607999 = header.getOrDefault("X-Amz-Security-Token")
  valid_607999 = validateParameter(valid_607999, JString, required = false,
                                 default = nil)
  if valid_607999 != nil:
    section.add "X-Amz-Security-Token", valid_607999
  var valid_608000 = header.getOrDefault("X-Amz-Algorithm")
  valid_608000 = validateParameter(valid_608000, JString, required = false,
                                 default = nil)
  if valid_608000 != nil:
    section.add "X-Amz-Algorithm", valid_608000
  var valid_608001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608001 = validateParameter(valid_608001, JString, required = false,
                                 default = nil)
  if valid_608001 != nil:
    section.add "X-Amz-SignedHeaders", valid_608001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608003: Call_UpdateJob_607991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_608003.validator(path, query, header, formData, body)
  let scheme = call_608003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608003.url(scheme.get, call_608003.host, call_608003.base,
                         call_608003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608003, url, valid)

proc call*(call_608004: Call_UpdateJob_607991; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_608005 = newJObject()
  if body != nil:
    body_608005 = body
  result = call_608004.call(nil, nil, nil, nil, body_608005)

var updateJob* = Call_UpdateJob_607991(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_607992,
                                    base: "/", url: url_UpdateJob_607993,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_608006 = ref object of OpenApiRestCall_605589
proc url_UpdateMLTransform_608008(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMLTransform_608007(path: JsonNode; query: JsonNode;
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
  var valid_608009 = header.getOrDefault("X-Amz-Target")
  valid_608009 = validateParameter(valid_608009, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_608009 != nil:
    section.add "X-Amz-Target", valid_608009
  var valid_608010 = header.getOrDefault("X-Amz-Signature")
  valid_608010 = validateParameter(valid_608010, JString, required = false,
                                 default = nil)
  if valid_608010 != nil:
    section.add "X-Amz-Signature", valid_608010
  var valid_608011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608011 = validateParameter(valid_608011, JString, required = false,
                                 default = nil)
  if valid_608011 != nil:
    section.add "X-Amz-Content-Sha256", valid_608011
  var valid_608012 = header.getOrDefault("X-Amz-Date")
  valid_608012 = validateParameter(valid_608012, JString, required = false,
                                 default = nil)
  if valid_608012 != nil:
    section.add "X-Amz-Date", valid_608012
  var valid_608013 = header.getOrDefault("X-Amz-Credential")
  valid_608013 = validateParameter(valid_608013, JString, required = false,
                                 default = nil)
  if valid_608013 != nil:
    section.add "X-Amz-Credential", valid_608013
  var valid_608014 = header.getOrDefault("X-Amz-Security-Token")
  valid_608014 = validateParameter(valid_608014, JString, required = false,
                                 default = nil)
  if valid_608014 != nil:
    section.add "X-Amz-Security-Token", valid_608014
  var valid_608015 = header.getOrDefault("X-Amz-Algorithm")
  valid_608015 = validateParameter(valid_608015, JString, required = false,
                                 default = nil)
  if valid_608015 != nil:
    section.add "X-Amz-Algorithm", valid_608015
  var valid_608016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608016 = validateParameter(valid_608016, JString, required = false,
                                 default = nil)
  if valid_608016 != nil:
    section.add "X-Amz-SignedHeaders", valid_608016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608018: Call_UpdateMLTransform_608006; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_608018.validator(path, query, header, formData, body)
  let scheme = call_608018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608018.url(scheme.get, call_608018.host, call_608018.base,
                         call_608018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608018, url, valid)

proc call*(call_608019: Call_UpdateMLTransform_608006; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_608020 = newJObject()
  if body != nil:
    body_608020 = body
  result = call_608019.call(nil, nil, nil, nil, body_608020)

var updateMLTransform* = Call_UpdateMLTransform_608006(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_608007, base: "/",
    url: url_UpdateMLTransform_608008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_608021 = ref object of OpenApiRestCall_605589
proc url_UpdatePartition_608023(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePartition_608022(path: JsonNode; query: JsonNode;
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
  var valid_608024 = header.getOrDefault("X-Amz-Target")
  valid_608024 = validateParameter(valid_608024, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_608024 != nil:
    section.add "X-Amz-Target", valid_608024
  var valid_608025 = header.getOrDefault("X-Amz-Signature")
  valid_608025 = validateParameter(valid_608025, JString, required = false,
                                 default = nil)
  if valid_608025 != nil:
    section.add "X-Amz-Signature", valid_608025
  var valid_608026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608026 = validateParameter(valid_608026, JString, required = false,
                                 default = nil)
  if valid_608026 != nil:
    section.add "X-Amz-Content-Sha256", valid_608026
  var valid_608027 = header.getOrDefault("X-Amz-Date")
  valid_608027 = validateParameter(valid_608027, JString, required = false,
                                 default = nil)
  if valid_608027 != nil:
    section.add "X-Amz-Date", valid_608027
  var valid_608028 = header.getOrDefault("X-Amz-Credential")
  valid_608028 = validateParameter(valid_608028, JString, required = false,
                                 default = nil)
  if valid_608028 != nil:
    section.add "X-Amz-Credential", valid_608028
  var valid_608029 = header.getOrDefault("X-Amz-Security-Token")
  valid_608029 = validateParameter(valid_608029, JString, required = false,
                                 default = nil)
  if valid_608029 != nil:
    section.add "X-Amz-Security-Token", valid_608029
  var valid_608030 = header.getOrDefault("X-Amz-Algorithm")
  valid_608030 = validateParameter(valid_608030, JString, required = false,
                                 default = nil)
  if valid_608030 != nil:
    section.add "X-Amz-Algorithm", valid_608030
  var valid_608031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608031 = validateParameter(valid_608031, JString, required = false,
                                 default = nil)
  if valid_608031 != nil:
    section.add "X-Amz-SignedHeaders", valid_608031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608033: Call_UpdatePartition_608021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_608033.validator(path, query, header, formData, body)
  let scheme = call_608033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608033.url(scheme.get, call_608033.host, call_608033.base,
                         call_608033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608033, url, valid)

proc call*(call_608034: Call_UpdatePartition_608021; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_608035 = newJObject()
  if body != nil:
    body_608035 = body
  result = call_608034.call(nil, nil, nil, nil, body_608035)

var updatePartition* = Call_UpdatePartition_608021(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_608022, base: "/", url: url_UpdatePartition_608023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_608036 = ref object of OpenApiRestCall_605589
proc url_UpdateTable_608038(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTable_608037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608039 = header.getOrDefault("X-Amz-Target")
  valid_608039 = validateParameter(valid_608039, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_608039 != nil:
    section.add "X-Amz-Target", valid_608039
  var valid_608040 = header.getOrDefault("X-Amz-Signature")
  valid_608040 = validateParameter(valid_608040, JString, required = false,
                                 default = nil)
  if valid_608040 != nil:
    section.add "X-Amz-Signature", valid_608040
  var valid_608041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608041 = validateParameter(valid_608041, JString, required = false,
                                 default = nil)
  if valid_608041 != nil:
    section.add "X-Amz-Content-Sha256", valid_608041
  var valid_608042 = header.getOrDefault("X-Amz-Date")
  valid_608042 = validateParameter(valid_608042, JString, required = false,
                                 default = nil)
  if valid_608042 != nil:
    section.add "X-Amz-Date", valid_608042
  var valid_608043 = header.getOrDefault("X-Amz-Credential")
  valid_608043 = validateParameter(valid_608043, JString, required = false,
                                 default = nil)
  if valid_608043 != nil:
    section.add "X-Amz-Credential", valid_608043
  var valid_608044 = header.getOrDefault("X-Amz-Security-Token")
  valid_608044 = validateParameter(valid_608044, JString, required = false,
                                 default = nil)
  if valid_608044 != nil:
    section.add "X-Amz-Security-Token", valid_608044
  var valid_608045 = header.getOrDefault("X-Amz-Algorithm")
  valid_608045 = validateParameter(valid_608045, JString, required = false,
                                 default = nil)
  if valid_608045 != nil:
    section.add "X-Amz-Algorithm", valid_608045
  var valid_608046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608046 = validateParameter(valid_608046, JString, required = false,
                                 default = nil)
  if valid_608046 != nil:
    section.add "X-Amz-SignedHeaders", valid_608046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608048: Call_UpdateTable_608036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_608048.validator(path, query, header, formData, body)
  let scheme = call_608048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608048.url(scheme.get, call_608048.host, call_608048.base,
                         call_608048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608048, url, valid)

proc call*(call_608049: Call_UpdateTable_608036; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_608050 = newJObject()
  if body != nil:
    body_608050 = body
  result = call_608049.call(nil, nil, nil, nil, body_608050)

var updateTable* = Call_UpdateTable_608036(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_608037,
                                        base: "/", url: url_UpdateTable_608038,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_608051 = ref object of OpenApiRestCall_605589
proc url_UpdateTrigger_608053(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrigger_608052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608054 = header.getOrDefault("X-Amz-Target")
  valid_608054 = validateParameter(valid_608054, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_608054 != nil:
    section.add "X-Amz-Target", valid_608054
  var valid_608055 = header.getOrDefault("X-Amz-Signature")
  valid_608055 = validateParameter(valid_608055, JString, required = false,
                                 default = nil)
  if valid_608055 != nil:
    section.add "X-Amz-Signature", valid_608055
  var valid_608056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608056 = validateParameter(valid_608056, JString, required = false,
                                 default = nil)
  if valid_608056 != nil:
    section.add "X-Amz-Content-Sha256", valid_608056
  var valid_608057 = header.getOrDefault("X-Amz-Date")
  valid_608057 = validateParameter(valid_608057, JString, required = false,
                                 default = nil)
  if valid_608057 != nil:
    section.add "X-Amz-Date", valid_608057
  var valid_608058 = header.getOrDefault("X-Amz-Credential")
  valid_608058 = validateParameter(valid_608058, JString, required = false,
                                 default = nil)
  if valid_608058 != nil:
    section.add "X-Amz-Credential", valid_608058
  var valid_608059 = header.getOrDefault("X-Amz-Security-Token")
  valid_608059 = validateParameter(valid_608059, JString, required = false,
                                 default = nil)
  if valid_608059 != nil:
    section.add "X-Amz-Security-Token", valid_608059
  var valid_608060 = header.getOrDefault("X-Amz-Algorithm")
  valid_608060 = validateParameter(valid_608060, JString, required = false,
                                 default = nil)
  if valid_608060 != nil:
    section.add "X-Amz-Algorithm", valid_608060
  var valid_608061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608061 = validateParameter(valid_608061, JString, required = false,
                                 default = nil)
  if valid_608061 != nil:
    section.add "X-Amz-SignedHeaders", valid_608061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608063: Call_UpdateTrigger_608051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_608063.validator(path, query, header, formData, body)
  let scheme = call_608063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608063.url(scheme.get, call_608063.host, call_608063.base,
                         call_608063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608063, url, valid)

proc call*(call_608064: Call_UpdateTrigger_608051; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_608065 = newJObject()
  if body != nil:
    body_608065 = body
  result = call_608064.call(nil, nil, nil, nil, body_608065)

var updateTrigger* = Call_UpdateTrigger_608051(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_608052, base: "/", url: url_UpdateTrigger_608053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_608066 = ref object of OpenApiRestCall_605589
proc url_UpdateUserDefinedFunction_608068(protocol: Scheme; host: string;
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

proc validate_UpdateUserDefinedFunction_608067(path: JsonNode; query: JsonNode;
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
  var valid_608069 = header.getOrDefault("X-Amz-Target")
  valid_608069 = validateParameter(valid_608069, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_608069 != nil:
    section.add "X-Amz-Target", valid_608069
  var valid_608070 = header.getOrDefault("X-Amz-Signature")
  valid_608070 = validateParameter(valid_608070, JString, required = false,
                                 default = nil)
  if valid_608070 != nil:
    section.add "X-Amz-Signature", valid_608070
  var valid_608071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608071 = validateParameter(valid_608071, JString, required = false,
                                 default = nil)
  if valid_608071 != nil:
    section.add "X-Amz-Content-Sha256", valid_608071
  var valid_608072 = header.getOrDefault("X-Amz-Date")
  valid_608072 = validateParameter(valid_608072, JString, required = false,
                                 default = nil)
  if valid_608072 != nil:
    section.add "X-Amz-Date", valid_608072
  var valid_608073 = header.getOrDefault("X-Amz-Credential")
  valid_608073 = validateParameter(valid_608073, JString, required = false,
                                 default = nil)
  if valid_608073 != nil:
    section.add "X-Amz-Credential", valid_608073
  var valid_608074 = header.getOrDefault("X-Amz-Security-Token")
  valid_608074 = validateParameter(valid_608074, JString, required = false,
                                 default = nil)
  if valid_608074 != nil:
    section.add "X-Amz-Security-Token", valid_608074
  var valid_608075 = header.getOrDefault("X-Amz-Algorithm")
  valid_608075 = validateParameter(valid_608075, JString, required = false,
                                 default = nil)
  if valid_608075 != nil:
    section.add "X-Amz-Algorithm", valid_608075
  var valid_608076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608076 = validateParameter(valid_608076, JString, required = false,
                                 default = nil)
  if valid_608076 != nil:
    section.add "X-Amz-SignedHeaders", valid_608076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608078: Call_UpdateUserDefinedFunction_608066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_608078.validator(path, query, header, formData, body)
  let scheme = call_608078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608078.url(scheme.get, call_608078.host, call_608078.base,
                         call_608078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608078, url, valid)

proc call*(call_608079: Call_UpdateUserDefinedFunction_608066; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_608080 = newJObject()
  if body != nil:
    body_608080 = body
  result = call_608079.call(nil, nil, nil, nil, body_608080)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_608066(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_608067, base: "/",
    url: url_UpdateUserDefinedFunction_608068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_608081 = ref object of OpenApiRestCall_605589
proc url_UpdateWorkflow_608083(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWorkflow_608082(path: JsonNode; query: JsonNode;
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
  var valid_608084 = header.getOrDefault("X-Amz-Target")
  valid_608084 = validateParameter(valid_608084, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_608084 != nil:
    section.add "X-Amz-Target", valid_608084
  var valid_608085 = header.getOrDefault("X-Amz-Signature")
  valid_608085 = validateParameter(valid_608085, JString, required = false,
                                 default = nil)
  if valid_608085 != nil:
    section.add "X-Amz-Signature", valid_608085
  var valid_608086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608086 = validateParameter(valid_608086, JString, required = false,
                                 default = nil)
  if valid_608086 != nil:
    section.add "X-Amz-Content-Sha256", valid_608086
  var valid_608087 = header.getOrDefault("X-Amz-Date")
  valid_608087 = validateParameter(valid_608087, JString, required = false,
                                 default = nil)
  if valid_608087 != nil:
    section.add "X-Amz-Date", valid_608087
  var valid_608088 = header.getOrDefault("X-Amz-Credential")
  valid_608088 = validateParameter(valid_608088, JString, required = false,
                                 default = nil)
  if valid_608088 != nil:
    section.add "X-Amz-Credential", valid_608088
  var valid_608089 = header.getOrDefault("X-Amz-Security-Token")
  valid_608089 = validateParameter(valid_608089, JString, required = false,
                                 default = nil)
  if valid_608089 != nil:
    section.add "X-Amz-Security-Token", valid_608089
  var valid_608090 = header.getOrDefault("X-Amz-Algorithm")
  valid_608090 = validateParameter(valid_608090, JString, required = false,
                                 default = nil)
  if valid_608090 != nil:
    section.add "X-Amz-Algorithm", valid_608090
  var valid_608091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608091 = validateParameter(valid_608091, JString, required = false,
                                 default = nil)
  if valid_608091 != nil:
    section.add "X-Amz-SignedHeaders", valid_608091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608093: Call_UpdateWorkflow_608081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_608093.validator(path, query, header, formData, body)
  let scheme = call_608093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608093.url(scheme.get, call_608093.host, call_608093.base,
                         call_608093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608093, url, valid)

proc call*(call_608094: Call_UpdateWorkflow_608081; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_608095 = newJObject()
  if body != nil:
    body_608095 = body
  result = call_608094.call(nil, nil, nil, nil, body_608095)

var updateWorkflow* = Call_UpdateWorkflow_608081(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_608082, base: "/", url: url_UpdateWorkflow_608083,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)

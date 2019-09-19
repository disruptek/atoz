
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_772933 = ref object of OpenApiRestCall_772597
proc url_BatchCreatePartition_772935(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchCreatePartition_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_BatchCreatePartition_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_BatchCreatePartition_772933; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var batchCreatePartition* = Call_BatchCreatePartition_772933(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_772934, base: "/",
    url: url_BatchCreatePartition_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_773202 = ref object of OpenApiRestCall_772597
proc url_BatchDeleteConnection_773204(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeleteConnection_773203(path: JsonNode; query: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_BatchDeleteConnection_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_BatchDeleteConnection_773202; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var batchDeleteConnection* = Call_BatchDeleteConnection_773202(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_773203, base: "/",
    url: url_BatchDeleteConnection_773204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_773217 = ref object of OpenApiRestCall_772597
proc url_BatchDeletePartition_773219(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeletePartition_773218(path: JsonNode; query: JsonNode;
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_BatchDeletePartition_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_BatchDeletePartition_773217; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var batchDeletePartition* = Call_BatchDeletePartition_773217(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_773218, base: "/",
    url: url_BatchDeletePartition_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_773232 = ref object of OpenApiRestCall_772597
proc url_BatchDeleteTable_773234(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeleteTable_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_BatchDeleteTable_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_BatchDeleteTable_773232; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var batchDeleteTable* = Call_BatchDeleteTable_773232(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_773233, base: "/",
    url: url_BatchDeleteTable_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_773247 = ref object of OpenApiRestCall_772597
proc url_BatchDeleteTableVersion_773249(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeleteTableVersion_773248(path: JsonNode; query: JsonNode;
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_BatchDeleteTableVersion_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_BatchDeleteTableVersion_773247; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_773247(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_773248, base: "/",
    url: url_BatchDeleteTableVersion_773249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_773262 = ref object of OpenApiRestCall_772597
proc url_BatchGetCrawlers_773264(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetCrawlers_773263(path: JsonNode; query: JsonNode;
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_BatchGetCrawlers_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_BatchGetCrawlers_773262; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var batchGetCrawlers* = Call_BatchGetCrawlers_773262(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_773263, base: "/",
    url: url_BatchGetCrawlers_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_773277 = ref object of OpenApiRestCall_772597
proc url_BatchGetDevEndpoints_773279(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetDevEndpoints_773278(path: JsonNode; query: JsonNode;
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_BatchGetDevEndpoints_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_BatchGetDevEndpoints_773277; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_773277(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_773278, base: "/",
    url: url_BatchGetDevEndpoints_773279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_773292 = ref object of OpenApiRestCall_772597
proc url_BatchGetJobs_773294(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetJobs_773293(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_BatchGetJobs_773292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_BatchGetJobs_773292; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var batchGetJobs* = Call_BatchGetJobs_773292(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_773293, base: "/", url: url_BatchGetJobs_773294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_773307 = ref object of OpenApiRestCall_772597
proc url_BatchGetPartition_773309(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetPartition_773308(path: JsonNode; query: JsonNode;
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
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_BatchGetPartition_773307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_BatchGetPartition_773307; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var batchGetPartition* = Call_BatchGetPartition_773307(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_773308, base: "/",
    url: url_BatchGetPartition_773309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_773322 = ref object of OpenApiRestCall_772597
proc url_BatchGetTriggers_773324(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetTriggers_773323(path: JsonNode; query: JsonNode;
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_BatchGetTriggers_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_BatchGetTriggers_773322; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var batchGetTriggers* = Call_BatchGetTriggers_773322(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_773323, base: "/",
    url: url_BatchGetTriggers_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_773337 = ref object of OpenApiRestCall_772597
proc url_BatchGetWorkflows_773339(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetWorkflows_773338(path: JsonNode; query: JsonNode;
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_BatchGetWorkflows_773337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_BatchGetWorkflows_773337; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var batchGetWorkflows* = Call_BatchGetWorkflows_773337(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_773338, base: "/",
    url: url_BatchGetWorkflows_773339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_773352 = ref object of OpenApiRestCall_772597
proc url_BatchStopJobRun_773354(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchStopJobRun_773353(path: JsonNode; query: JsonNode;
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773357 = header.getOrDefault("X-Amz-Target")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_773357 != nil:
    section.add "X-Amz-Target", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_BatchStopJobRun_773352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_BatchStopJobRun_773352; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_773366 = newJObject()
  if body != nil:
    body_773366 = body
  result = call_773365.call(nil, nil, nil, nil, body_773366)

var batchStopJobRun* = Call_BatchStopJobRun_773352(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_773353, base: "/", url: url_BatchStopJobRun_773354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_773367 = ref object of OpenApiRestCall_772597
proc url_CancelMLTaskRun_773369(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelMLTaskRun_773368(path: JsonNode; query: JsonNode;
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773372 = header.getOrDefault("X-Amz-Target")
  valid_773372 = validateParameter(valid_773372, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_773372 != nil:
    section.add "X-Amz-Target", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_CancelMLTaskRun_773367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_CancelMLTaskRun_773367; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_773381 = newJObject()
  if body != nil:
    body_773381 = body
  result = call_773380.call(nil, nil, nil, nil, body_773381)

var cancelMLTaskRun* = Call_CancelMLTaskRun_773367(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_773368, base: "/", url: url_CancelMLTaskRun_773369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_773382 = ref object of OpenApiRestCall_772597
proc url_CreateClassifier_773384(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateClassifier_773383(path: JsonNode; query: JsonNode;
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773387 = header.getOrDefault("X-Amz-Target")
  valid_773387 = validateParameter(valid_773387, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_773387 != nil:
    section.add "X-Amz-Target", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_CreateClassifier_773382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_CreateClassifier_773382; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_773396 = newJObject()
  if body != nil:
    body_773396 = body
  result = call_773395.call(nil, nil, nil, nil, body_773396)

var createClassifier* = Call_CreateClassifier_773382(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_773383, base: "/",
    url: url_CreateClassifier_773384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_773397 = ref object of OpenApiRestCall_772597
proc url_CreateConnection_773399(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateConnection_773398(path: JsonNode; query: JsonNode;
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
  var valid_773400 = header.getOrDefault("X-Amz-Date")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Date", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Security-Token")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Security-Token", valid_773401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773402 = header.getOrDefault("X-Amz-Target")
  valid_773402 = validateParameter(valid_773402, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_773402 != nil:
    section.add "X-Amz-Target", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Content-Sha256", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Algorithm")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Algorithm", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Signature")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Signature", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-SignedHeaders", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Credential")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Credential", valid_773407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_CreateConnection_773397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_CreateConnection_773397; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_773411 = newJObject()
  if body != nil:
    body_773411 = body
  result = call_773410.call(nil, nil, nil, nil, body_773411)

var createConnection* = Call_CreateConnection_773397(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_773398, base: "/",
    url: url_CreateConnection_773399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_773412 = ref object of OpenApiRestCall_772597
proc url_CreateCrawler_773414(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCrawler_773413(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773415 = header.getOrDefault("X-Amz-Date")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Date", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Security-Token")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Security-Token", valid_773416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773417 = header.getOrDefault("X-Amz-Target")
  valid_773417 = validateParameter(valid_773417, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_773417 != nil:
    section.add "X-Amz-Target", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Content-Sha256", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Algorithm")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Algorithm", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Signature")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Signature", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-SignedHeaders", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Credential")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Credential", valid_773422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773424: Call_CreateCrawler_773412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_773424.validator(path, query, header, formData, body)
  let scheme = call_773424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773424.url(scheme.get, call_773424.host, call_773424.base,
                         call_773424.route, valid.getOrDefault("path"))
  result = hook(call_773424, url, valid)

proc call*(call_773425: Call_CreateCrawler_773412; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_773426 = newJObject()
  if body != nil:
    body_773426 = body
  result = call_773425.call(nil, nil, nil, nil, body_773426)

var createCrawler* = Call_CreateCrawler_773412(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_773413, base: "/", url: url_CreateCrawler_773414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_773427 = ref object of OpenApiRestCall_772597
proc url_CreateDatabase_773429(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDatabase_773428(path: JsonNode; query: JsonNode;
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
  var valid_773430 = header.getOrDefault("X-Amz-Date")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Date", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Security-Token")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Security-Token", valid_773431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773432 = header.getOrDefault("X-Amz-Target")
  valid_773432 = validateParameter(valid_773432, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_773432 != nil:
    section.add "X-Amz-Target", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Content-Sha256", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Algorithm")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Algorithm", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Signature")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Signature", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-SignedHeaders", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Credential")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Credential", valid_773437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773439: Call_CreateDatabase_773427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_773439.validator(path, query, header, formData, body)
  let scheme = call_773439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773439.url(scheme.get, call_773439.host, call_773439.base,
                         call_773439.route, valid.getOrDefault("path"))
  result = hook(call_773439, url, valid)

proc call*(call_773440: Call_CreateDatabase_773427; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_773441 = newJObject()
  if body != nil:
    body_773441 = body
  result = call_773440.call(nil, nil, nil, nil, body_773441)

var createDatabase* = Call_CreateDatabase_773427(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_773428, base: "/", url: url_CreateDatabase_773429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_773442 = ref object of OpenApiRestCall_772597
proc url_CreateDevEndpoint_773444(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDevEndpoint_773443(path: JsonNode; query: JsonNode;
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
  var valid_773445 = header.getOrDefault("X-Amz-Date")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Date", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Security-Token")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Security-Token", valid_773446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773447 = header.getOrDefault("X-Amz-Target")
  valid_773447 = validateParameter(valid_773447, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_773447 != nil:
    section.add "X-Amz-Target", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773454: Call_CreateDevEndpoint_773442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_773454.validator(path, query, header, formData, body)
  let scheme = call_773454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773454.url(scheme.get, call_773454.host, call_773454.base,
                         call_773454.route, valid.getOrDefault("path"))
  result = hook(call_773454, url, valid)

proc call*(call_773455: Call_CreateDevEndpoint_773442; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_773456 = newJObject()
  if body != nil:
    body_773456 = body
  result = call_773455.call(nil, nil, nil, nil, body_773456)

var createDevEndpoint* = Call_CreateDevEndpoint_773442(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_773443, base: "/",
    url: url_CreateDevEndpoint_773444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_773457 = ref object of OpenApiRestCall_772597
proc url_CreateJob_773459(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateJob_773458(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773460 = header.getOrDefault("X-Amz-Date")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Date", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Security-Token")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Security-Token", valid_773461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773462 = header.getOrDefault("X-Amz-Target")
  valid_773462 = validateParameter(valid_773462, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_773462 != nil:
    section.add "X-Amz-Target", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Content-Sha256", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Algorithm")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Algorithm", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Signature")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Signature", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-SignedHeaders", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Credential")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Credential", valid_773467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773469: Call_CreateJob_773457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_773469.validator(path, query, header, formData, body)
  let scheme = call_773469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773469.url(scheme.get, call_773469.host, call_773469.base,
                         call_773469.route, valid.getOrDefault("path"))
  result = hook(call_773469, url, valid)

proc call*(call_773470: Call_CreateJob_773457; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_773471 = newJObject()
  if body != nil:
    body_773471 = body
  result = call_773470.call(nil, nil, nil, nil, body_773471)

var createJob* = Call_CreateJob_773457(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_773458,
                                    base: "/", url: url_CreateJob_773459,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_773472 = ref object of OpenApiRestCall_772597
proc url_CreateMLTransform_773474(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMLTransform_773473(path: JsonNode; query: JsonNode;
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
  var valid_773475 = header.getOrDefault("X-Amz-Date")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Date", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Security-Token")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Security-Token", valid_773476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773477 = header.getOrDefault("X-Amz-Target")
  valid_773477 = validateParameter(valid_773477, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_773477 != nil:
    section.add "X-Amz-Target", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Content-Sha256", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Algorithm")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Algorithm", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Signature")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Signature", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-SignedHeaders", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Credential")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Credential", valid_773482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773484: Call_CreateMLTransform_773472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_773484.validator(path, query, header, formData, body)
  let scheme = call_773484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773484.url(scheme.get, call_773484.host, call_773484.base,
                         call_773484.route, valid.getOrDefault("path"))
  result = hook(call_773484, url, valid)

proc call*(call_773485: Call_CreateMLTransform_773472; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_773486 = newJObject()
  if body != nil:
    body_773486 = body
  result = call_773485.call(nil, nil, nil, nil, body_773486)

var createMLTransform* = Call_CreateMLTransform_773472(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_773473, base: "/",
    url: url_CreateMLTransform_773474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_773487 = ref object of OpenApiRestCall_772597
proc url_CreatePartition_773489(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePartition_773488(path: JsonNode; query: JsonNode;
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
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773492 = header.getOrDefault("X-Amz-Target")
  valid_773492 = validateParameter(valid_773492, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_773492 != nil:
    section.add "X-Amz-Target", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Content-Sha256", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Algorithm")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Algorithm", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Signature")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Signature", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-SignedHeaders", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Credential")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Credential", valid_773497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773499: Call_CreatePartition_773487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_773499.validator(path, query, header, formData, body)
  let scheme = call_773499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773499.url(scheme.get, call_773499.host, call_773499.base,
                         call_773499.route, valid.getOrDefault("path"))
  result = hook(call_773499, url, valid)

proc call*(call_773500: Call_CreatePartition_773487; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_773501 = newJObject()
  if body != nil:
    body_773501 = body
  result = call_773500.call(nil, nil, nil, nil, body_773501)

var createPartition* = Call_CreatePartition_773487(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_773488, base: "/", url: url_CreatePartition_773489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_773502 = ref object of OpenApiRestCall_772597
proc url_CreateScript_773504(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateScript_773503(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773505 = header.getOrDefault("X-Amz-Date")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Date", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Security-Token")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Security-Token", valid_773506
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773507 = header.getOrDefault("X-Amz-Target")
  valid_773507 = validateParameter(valid_773507, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_773507 != nil:
    section.add "X-Amz-Target", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773514: Call_CreateScript_773502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_773514.validator(path, query, header, formData, body)
  let scheme = call_773514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773514.url(scheme.get, call_773514.host, call_773514.base,
                         call_773514.route, valid.getOrDefault("path"))
  result = hook(call_773514, url, valid)

proc call*(call_773515: Call_CreateScript_773502; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_773516 = newJObject()
  if body != nil:
    body_773516 = body
  result = call_773515.call(nil, nil, nil, nil, body_773516)

var createScript* = Call_CreateScript_773502(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_773503, base: "/", url: url_CreateScript_773504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_773517 = ref object of OpenApiRestCall_772597
proc url_CreateSecurityConfiguration_773519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSecurityConfiguration_773518(path: JsonNode; query: JsonNode;
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
  var valid_773520 = header.getOrDefault("X-Amz-Date")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Date", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Security-Token")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Security-Token", valid_773521
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773522 = header.getOrDefault("X-Amz-Target")
  valid_773522 = validateParameter(valid_773522, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_773522 != nil:
    section.add "X-Amz-Target", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Content-Sha256", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Algorithm")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Algorithm", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Signature")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Signature", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-SignedHeaders", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Credential")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Credential", valid_773527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773529: Call_CreateSecurityConfiguration_773517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_773529.validator(path, query, header, formData, body)
  let scheme = call_773529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773529.url(scheme.get, call_773529.host, call_773529.base,
                         call_773529.route, valid.getOrDefault("path"))
  result = hook(call_773529, url, valid)

proc call*(call_773530: Call_CreateSecurityConfiguration_773517; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_773531 = newJObject()
  if body != nil:
    body_773531 = body
  result = call_773530.call(nil, nil, nil, nil, body_773531)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_773517(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_773518, base: "/",
    url: url_CreateSecurityConfiguration_773519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_773532 = ref object of OpenApiRestCall_772597
proc url_CreateTable_773534(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTable_773533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773535 = header.getOrDefault("X-Amz-Date")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Date", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Security-Token")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Security-Token", valid_773536
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773537 = header.getOrDefault("X-Amz-Target")
  valid_773537 = validateParameter(valid_773537, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_773537 != nil:
    section.add "X-Amz-Target", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Content-Sha256", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Algorithm")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Algorithm", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Signature")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Signature", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-SignedHeaders", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Credential")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Credential", valid_773542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773544: Call_CreateTable_773532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_773544.validator(path, query, header, formData, body)
  let scheme = call_773544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773544.url(scheme.get, call_773544.host, call_773544.base,
                         call_773544.route, valid.getOrDefault("path"))
  result = hook(call_773544, url, valid)

proc call*(call_773545: Call_CreateTable_773532; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_773546 = newJObject()
  if body != nil:
    body_773546 = body
  result = call_773545.call(nil, nil, nil, nil, body_773546)

var createTable* = Call_CreateTable_773532(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_773533,
                                        base: "/", url: url_CreateTable_773534,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_773547 = ref object of OpenApiRestCall_772597
proc url_CreateTrigger_773549(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTrigger_773548(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773550 = header.getOrDefault("X-Amz-Date")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Date", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Security-Token")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Security-Token", valid_773551
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773552 = header.getOrDefault("X-Amz-Target")
  valid_773552 = validateParameter(valid_773552, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_773552 != nil:
    section.add "X-Amz-Target", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Content-Sha256", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Algorithm")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Algorithm", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Signature")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Signature", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-SignedHeaders", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Credential")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Credential", valid_773557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773559: Call_CreateTrigger_773547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_773559.validator(path, query, header, formData, body)
  let scheme = call_773559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773559.url(scheme.get, call_773559.host, call_773559.base,
                         call_773559.route, valid.getOrDefault("path"))
  result = hook(call_773559, url, valid)

proc call*(call_773560: Call_CreateTrigger_773547; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_773561 = newJObject()
  if body != nil:
    body_773561 = body
  result = call_773560.call(nil, nil, nil, nil, body_773561)

var createTrigger* = Call_CreateTrigger_773547(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_773548, base: "/", url: url_CreateTrigger_773549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_773562 = ref object of OpenApiRestCall_772597
proc url_CreateUserDefinedFunction_773564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUserDefinedFunction_773563(path: JsonNode; query: JsonNode;
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
  var valid_773565 = header.getOrDefault("X-Amz-Date")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Date", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Security-Token")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Security-Token", valid_773566
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773567 = header.getOrDefault("X-Amz-Target")
  valid_773567 = validateParameter(valid_773567, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_773567 != nil:
    section.add "X-Amz-Target", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Content-Sha256", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Algorithm")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Algorithm", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Signature")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Signature", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-SignedHeaders", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Credential")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Credential", valid_773572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773574: Call_CreateUserDefinedFunction_773562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_773574.validator(path, query, header, formData, body)
  let scheme = call_773574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773574.url(scheme.get, call_773574.host, call_773574.base,
                         call_773574.route, valid.getOrDefault("path"))
  result = hook(call_773574, url, valid)

proc call*(call_773575: Call_CreateUserDefinedFunction_773562; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_773576 = newJObject()
  if body != nil:
    body_773576 = body
  result = call_773575.call(nil, nil, nil, nil, body_773576)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_773562(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_773563, base: "/",
    url: url_CreateUserDefinedFunction_773564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_773577 = ref object of OpenApiRestCall_772597
proc url_CreateWorkflow_773579(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateWorkflow_773578(path: JsonNode; query: JsonNode;
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
  var valid_773580 = header.getOrDefault("X-Amz-Date")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Date", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Security-Token")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Security-Token", valid_773581
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773582 = header.getOrDefault("X-Amz-Target")
  valid_773582 = validateParameter(valid_773582, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_773582 != nil:
    section.add "X-Amz-Target", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Content-Sha256", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Algorithm")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Algorithm", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Signature")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Signature", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-SignedHeaders", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Credential")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Credential", valid_773587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773589: Call_CreateWorkflow_773577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_773589.validator(path, query, header, formData, body)
  let scheme = call_773589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773589.url(scheme.get, call_773589.host, call_773589.base,
                         call_773589.route, valid.getOrDefault("path"))
  result = hook(call_773589, url, valid)

proc call*(call_773590: Call_CreateWorkflow_773577; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_773591 = newJObject()
  if body != nil:
    body_773591 = body
  result = call_773590.call(nil, nil, nil, nil, body_773591)

var createWorkflow* = Call_CreateWorkflow_773577(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_773578, base: "/", url: url_CreateWorkflow_773579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_773592 = ref object of OpenApiRestCall_772597
proc url_DeleteClassifier_773594(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteClassifier_773593(path: JsonNode; query: JsonNode;
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
  var valid_773595 = header.getOrDefault("X-Amz-Date")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Date", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Security-Token")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Security-Token", valid_773596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773597 = header.getOrDefault("X-Amz-Target")
  valid_773597 = validateParameter(valid_773597, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_773597 != nil:
    section.add "X-Amz-Target", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Content-Sha256", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Algorithm")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Algorithm", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Signature")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Signature", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-SignedHeaders", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Credential")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Credential", valid_773602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773604: Call_DeleteClassifier_773592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_773604.validator(path, query, header, formData, body)
  let scheme = call_773604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773604.url(scheme.get, call_773604.host, call_773604.base,
                         call_773604.route, valid.getOrDefault("path"))
  result = hook(call_773604, url, valid)

proc call*(call_773605: Call_DeleteClassifier_773592; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_773606 = newJObject()
  if body != nil:
    body_773606 = body
  result = call_773605.call(nil, nil, nil, nil, body_773606)

var deleteClassifier* = Call_DeleteClassifier_773592(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_773593, base: "/",
    url: url_DeleteClassifier_773594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_773607 = ref object of OpenApiRestCall_772597
proc url_DeleteConnection_773609(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteConnection_773608(path: JsonNode; query: JsonNode;
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
  var valid_773610 = header.getOrDefault("X-Amz-Date")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Date", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Security-Token")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Security-Token", valid_773611
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773612 = header.getOrDefault("X-Amz-Target")
  valid_773612 = validateParameter(valid_773612, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_773612 != nil:
    section.add "X-Amz-Target", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Content-Sha256", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Algorithm")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Algorithm", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Signature")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Signature", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-SignedHeaders", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Credential")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Credential", valid_773617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773619: Call_DeleteConnection_773607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_773619.validator(path, query, header, formData, body)
  let scheme = call_773619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773619.url(scheme.get, call_773619.host, call_773619.base,
                         call_773619.route, valid.getOrDefault("path"))
  result = hook(call_773619, url, valid)

proc call*(call_773620: Call_DeleteConnection_773607; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_773621 = newJObject()
  if body != nil:
    body_773621 = body
  result = call_773620.call(nil, nil, nil, nil, body_773621)

var deleteConnection* = Call_DeleteConnection_773607(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_773608, base: "/",
    url: url_DeleteConnection_773609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_773622 = ref object of OpenApiRestCall_772597
proc url_DeleteCrawler_773624(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCrawler_773623(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773625 = header.getOrDefault("X-Amz-Date")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Date", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Security-Token")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Security-Token", valid_773626
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773627 = header.getOrDefault("X-Amz-Target")
  valid_773627 = validateParameter(valid_773627, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_773627 != nil:
    section.add "X-Amz-Target", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Content-Sha256", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-Algorithm")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Algorithm", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Signature")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Signature", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-SignedHeaders", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Credential")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Credential", valid_773632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773634: Call_DeleteCrawler_773622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_773634.validator(path, query, header, formData, body)
  let scheme = call_773634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773634.url(scheme.get, call_773634.host, call_773634.base,
                         call_773634.route, valid.getOrDefault("path"))
  result = hook(call_773634, url, valid)

proc call*(call_773635: Call_DeleteCrawler_773622; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_773636 = newJObject()
  if body != nil:
    body_773636 = body
  result = call_773635.call(nil, nil, nil, nil, body_773636)

var deleteCrawler* = Call_DeleteCrawler_773622(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_773623, base: "/", url: url_DeleteCrawler_773624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_773637 = ref object of OpenApiRestCall_772597
proc url_DeleteDatabase_773639(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDatabase_773638(path: JsonNode; query: JsonNode;
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
  var valid_773640 = header.getOrDefault("X-Amz-Date")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Date", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Security-Token")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Security-Token", valid_773641
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773642 = header.getOrDefault("X-Amz-Target")
  valid_773642 = validateParameter(valid_773642, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_773642 != nil:
    section.add "X-Amz-Target", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Content-Sha256", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Algorithm")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Algorithm", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Signature")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Signature", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-SignedHeaders", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Credential")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Credential", valid_773647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773649: Call_DeleteDatabase_773637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_773649.validator(path, query, header, formData, body)
  let scheme = call_773649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773649.url(scheme.get, call_773649.host, call_773649.base,
                         call_773649.route, valid.getOrDefault("path"))
  result = hook(call_773649, url, valid)

proc call*(call_773650: Call_DeleteDatabase_773637; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_773651 = newJObject()
  if body != nil:
    body_773651 = body
  result = call_773650.call(nil, nil, nil, nil, body_773651)

var deleteDatabase* = Call_DeleteDatabase_773637(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_773638, base: "/", url: url_DeleteDatabase_773639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_773652 = ref object of OpenApiRestCall_772597
proc url_DeleteDevEndpoint_773654(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDevEndpoint_773653(path: JsonNode; query: JsonNode;
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
  var valid_773655 = header.getOrDefault("X-Amz-Date")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Date", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Security-Token")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Security-Token", valid_773656
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773657 = header.getOrDefault("X-Amz-Target")
  valid_773657 = validateParameter(valid_773657, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_773657 != nil:
    section.add "X-Amz-Target", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Content-Sha256", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Algorithm")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Algorithm", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Signature")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Signature", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-SignedHeaders", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Credential")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Credential", valid_773662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773664: Call_DeleteDevEndpoint_773652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_773664.validator(path, query, header, formData, body)
  let scheme = call_773664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773664.url(scheme.get, call_773664.host, call_773664.base,
                         call_773664.route, valid.getOrDefault("path"))
  result = hook(call_773664, url, valid)

proc call*(call_773665: Call_DeleteDevEndpoint_773652; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_773666 = newJObject()
  if body != nil:
    body_773666 = body
  result = call_773665.call(nil, nil, nil, nil, body_773666)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_773652(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_773653, base: "/",
    url: url_DeleteDevEndpoint_773654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_773667 = ref object of OpenApiRestCall_772597
proc url_DeleteJob_773669(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteJob_773668(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773670 = header.getOrDefault("X-Amz-Date")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Date", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Security-Token")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Security-Token", valid_773671
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773672 = header.getOrDefault("X-Amz-Target")
  valid_773672 = validateParameter(valid_773672, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_773672 != nil:
    section.add "X-Amz-Target", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-Content-Sha256", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Algorithm")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Algorithm", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Signature")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Signature", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-SignedHeaders", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Credential")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Credential", valid_773677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773679: Call_DeleteJob_773667; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_773679.validator(path, query, header, formData, body)
  let scheme = call_773679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773679.url(scheme.get, call_773679.host, call_773679.base,
                         call_773679.route, valid.getOrDefault("path"))
  result = hook(call_773679, url, valid)

proc call*(call_773680: Call_DeleteJob_773667; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_773681 = newJObject()
  if body != nil:
    body_773681 = body
  result = call_773680.call(nil, nil, nil, nil, body_773681)

var deleteJob* = Call_DeleteJob_773667(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_773668,
                                    base: "/", url: url_DeleteJob_773669,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_773682 = ref object of OpenApiRestCall_772597
proc url_DeleteMLTransform_773684(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteMLTransform_773683(path: JsonNode; query: JsonNode;
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
  var valid_773685 = header.getOrDefault("X-Amz-Date")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Date", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Security-Token")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Security-Token", valid_773686
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773687 = header.getOrDefault("X-Amz-Target")
  valid_773687 = validateParameter(valid_773687, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_773687 != nil:
    section.add "X-Amz-Target", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Content-Sha256", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Algorithm")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Algorithm", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Signature")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Signature", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-SignedHeaders", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Credential")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Credential", valid_773692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773694: Call_DeleteMLTransform_773682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_773694.validator(path, query, header, formData, body)
  let scheme = call_773694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773694.url(scheme.get, call_773694.host, call_773694.base,
                         call_773694.route, valid.getOrDefault("path"))
  result = hook(call_773694, url, valid)

proc call*(call_773695: Call_DeleteMLTransform_773682; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_773696 = newJObject()
  if body != nil:
    body_773696 = body
  result = call_773695.call(nil, nil, nil, nil, body_773696)

var deleteMLTransform* = Call_DeleteMLTransform_773682(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_773683, base: "/",
    url: url_DeleteMLTransform_773684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_773697 = ref object of OpenApiRestCall_772597
proc url_DeletePartition_773699(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeletePartition_773698(path: JsonNode; query: JsonNode;
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
  var valid_773700 = header.getOrDefault("X-Amz-Date")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Date", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Security-Token")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Security-Token", valid_773701
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773702 = header.getOrDefault("X-Amz-Target")
  valid_773702 = validateParameter(valid_773702, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_773702 != nil:
    section.add "X-Amz-Target", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Content-Sha256", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Algorithm")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Algorithm", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Signature")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Signature", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-SignedHeaders", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Credential")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Credential", valid_773707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773709: Call_DeletePartition_773697; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_773709.validator(path, query, header, formData, body)
  let scheme = call_773709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773709.url(scheme.get, call_773709.host, call_773709.base,
                         call_773709.route, valid.getOrDefault("path"))
  result = hook(call_773709, url, valid)

proc call*(call_773710: Call_DeletePartition_773697; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_773711 = newJObject()
  if body != nil:
    body_773711 = body
  result = call_773710.call(nil, nil, nil, nil, body_773711)

var deletePartition* = Call_DeletePartition_773697(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_773698, base: "/", url: url_DeletePartition_773699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_773712 = ref object of OpenApiRestCall_772597
proc url_DeleteResourcePolicy_773714(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourcePolicy_773713(path: JsonNode; query: JsonNode;
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
  var valid_773715 = header.getOrDefault("X-Amz-Date")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Date", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Security-Token")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Security-Token", valid_773716
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773717 = header.getOrDefault("X-Amz-Target")
  valid_773717 = validateParameter(valid_773717, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_773717 != nil:
    section.add "X-Amz-Target", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Content-Sha256", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Algorithm")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Algorithm", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Signature")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Signature", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-SignedHeaders", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Credential")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Credential", valid_773722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773724: Call_DeleteResourcePolicy_773712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_773724.validator(path, query, header, formData, body)
  let scheme = call_773724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773724.url(scheme.get, call_773724.host, call_773724.base,
                         call_773724.route, valid.getOrDefault("path"))
  result = hook(call_773724, url, valid)

proc call*(call_773725: Call_DeleteResourcePolicy_773712; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_773726 = newJObject()
  if body != nil:
    body_773726 = body
  result = call_773725.call(nil, nil, nil, nil, body_773726)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_773712(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_773713, base: "/",
    url: url_DeleteResourcePolicy_773714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_773727 = ref object of OpenApiRestCall_772597
proc url_DeleteSecurityConfiguration_773729(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSecurityConfiguration_773728(path: JsonNode; query: JsonNode;
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
  var valid_773730 = header.getOrDefault("X-Amz-Date")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Date", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Security-Token")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Security-Token", valid_773731
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773732 = header.getOrDefault("X-Amz-Target")
  valid_773732 = validateParameter(valid_773732, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_773732 != nil:
    section.add "X-Amz-Target", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Content-Sha256", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Algorithm")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Algorithm", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-Signature")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Signature", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-SignedHeaders", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Credential")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Credential", valid_773737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773739: Call_DeleteSecurityConfiguration_773727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_773739.validator(path, query, header, formData, body)
  let scheme = call_773739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773739.url(scheme.get, call_773739.host, call_773739.base,
                         call_773739.route, valid.getOrDefault("path"))
  result = hook(call_773739, url, valid)

proc call*(call_773740: Call_DeleteSecurityConfiguration_773727; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_773741 = newJObject()
  if body != nil:
    body_773741 = body
  result = call_773740.call(nil, nil, nil, nil, body_773741)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_773727(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_773728, base: "/",
    url: url_DeleteSecurityConfiguration_773729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_773742 = ref object of OpenApiRestCall_772597
proc url_DeleteTable_773744(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTable_773743(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773745 = header.getOrDefault("X-Amz-Date")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Date", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Security-Token")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Security-Token", valid_773746
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773747 = header.getOrDefault("X-Amz-Target")
  valid_773747 = validateParameter(valid_773747, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_773747 != nil:
    section.add "X-Amz-Target", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Content-Sha256", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Algorithm")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Algorithm", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Signature")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Signature", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-SignedHeaders", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Credential")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Credential", valid_773752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773754: Call_DeleteTable_773742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_773754.validator(path, query, header, formData, body)
  let scheme = call_773754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773754.url(scheme.get, call_773754.host, call_773754.base,
                         call_773754.route, valid.getOrDefault("path"))
  result = hook(call_773754, url, valid)

proc call*(call_773755: Call_DeleteTable_773742; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_773756 = newJObject()
  if body != nil:
    body_773756 = body
  result = call_773755.call(nil, nil, nil, nil, body_773756)

var deleteTable* = Call_DeleteTable_773742(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_773743,
                                        base: "/", url: url_DeleteTable_773744,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_773757 = ref object of OpenApiRestCall_772597
proc url_DeleteTableVersion_773759(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTableVersion_773758(path: JsonNode; query: JsonNode;
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
  var valid_773760 = header.getOrDefault("X-Amz-Date")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Date", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Security-Token")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Security-Token", valid_773761
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773762 = header.getOrDefault("X-Amz-Target")
  valid_773762 = validateParameter(valid_773762, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_773762 != nil:
    section.add "X-Amz-Target", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Content-Sha256", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Algorithm")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Algorithm", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Signature")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Signature", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-SignedHeaders", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-Credential")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Credential", valid_773767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773769: Call_DeleteTableVersion_773757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_773769.validator(path, query, header, formData, body)
  let scheme = call_773769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773769.url(scheme.get, call_773769.host, call_773769.base,
                         call_773769.route, valid.getOrDefault("path"))
  result = hook(call_773769, url, valid)

proc call*(call_773770: Call_DeleteTableVersion_773757; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_773771 = newJObject()
  if body != nil:
    body_773771 = body
  result = call_773770.call(nil, nil, nil, nil, body_773771)

var deleteTableVersion* = Call_DeleteTableVersion_773757(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_773758, base: "/",
    url: url_DeleteTableVersion_773759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_773772 = ref object of OpenApiRestCall_772597
proc url_DeleteTrigger_773774(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTrigger_773773(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773775 = header.getOrDefault("X-Amz-Date")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-Date", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Security-Token")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Security-Token", valid_773776
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773777 = header.getOrDefault("X-Amz-Target")
  valid_773777 = validateParameter(valid_773777, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_773777 != nil:
    section.add "X-Amz-Target", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Content-Sha256", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Algorithm")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Algorithm", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Signature")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Signature", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-SignedHeaders", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-Credential")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Credential", valid_773782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773784: Call_DeleteTrigger_773772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_773784.validator(path, query, header, formData, body)
  let scheme = call_773784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773784.url(scheme.get, call_773784.host, call_773784.base,
                         call_773784.route, valid.getOrDefault("path"))
  result = hook(call_773784, url, valid)

proc call*(call_773785: Call_DeleteTrigger_773772; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_773786 = newJObject()
  if body != nil:
    body_773786 = body
  result = call_773785.call(nil, nil, nil, nil, body_773786)

var deleteTrigger* = Call_DeleteTrigger_773772(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_773773, base: "/", url: url_DeleteTrigger_773774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_773787 = ref object of OpenApiRestCall_772597
proc url_DeleteUserDefinedFunction_773789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUserDefinedFunction_773788(path: JsonNode; query: JsonNode;
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
  var valid_773790 = header.getOrDefault("X-Amz-Date")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Date", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Security-Token")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Security-Token", valid_773791
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773792 = header.getOrDefault("X-Amz-Target")
  valid_773792 = validateParameter(valid_773792, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_773792 != nil:
    section.add "X-Amz-Target", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Content-Sha256", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Algorithm")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Algorithm", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-Signature")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Signature", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-SignedHeaders", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-Credential")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Credential", valid_773797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773799: Call_DeleteUserDefinedFunction_773787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_773799.validator(path, query, header, formData, body)
  let scheme = call_773799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773799.url(scheme.get, call_773799.host, call_773799.base,
                         call_773799.route, valid.getOrDefault("path"))
  result = hook(call_773799, url, valid)

proc call*(call_773800: Call_DeleteUserDefinedFunction_773787; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_773801 = newJObject()
  if body != nil:
    body_773801 = body
  result = call_773800.call(nil, nil, nil, nil, body_773801)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_773787(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_773788, base: "/",
    url: url_DeleteUserDefinedFunction_773789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_773802 = ref object of OpenApiRestCall_772597
proc url_DeleteWorkflow_773804(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteWorkflow_773803(path: JsonNode; query: JsonNode;
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
  var valid_773805 = header.getOrDefault("X-Amz-Date")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Date", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Security-Token")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Security-Token", valid_773806
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773807 = header.getOrDefault("X-Amz-Target")
  valid_773807 = validateParameter(valid_773807, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_773807 != nil:
    section.add "X-Amz-Target", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Content-Sha256", valid_773808
  var valid_773809 = header.getOrDefault("X-Amz-Algorithm")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-Algorithm", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-Signature")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-Signature", valid_773810
  var valid_773811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-SignedHeaders", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-Credential")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Credential", valid_773812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773814: Call_DeleteWorkflow_773802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_773814.validator(path, query, header, formData, body)
  let scheme = call_773814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773814.url(scheme.get, call_773814.host, call_773814.base,
                         call_773814.route, valid.getOrDefault("path"))
  result = hook(call_773814, url, valid)

proc call*(call_773815: Call_DeleteWorkflow_773802; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_773816 = newJObject()
  if body != nil:
    body_773816 = body
  result = call_773815.call(nil, nil, nil, nil, body_773816)

var deleteWorkflow* = Call_DeleteWorkflow_773802(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_773803, base: "/", url: url_DeleteWorkflow_773804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_773817 = ref object of OpenApiRestCall_772597
proc url_GetCatalogImportStatus_773819(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCatalogImportStatus_773818(path: JsonNode; query: JsonNode;
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
  var valid_773820 = header.getOrDefault("X-Amz-Date")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Date", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Security-Token")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Security-Token", valid_773821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773822 = header.getOrDefault("X-Amz-Target")
  valid_773822 = validateParameter(valid_773822, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_773822 != nil:
    section.add "X-Amz-Target", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Content-Sha256", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Algorithm")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Algorithm", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-Signature")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-Signature", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-SignedHeaders", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Credential")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Credential", valid_773827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773829: Call_GetCatalogImportStatus_773817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_773829.validator(path, query, header, formData, body)
  let scheme = call_773829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773829.url(scheme.get, call_773829.host, call_773829.base,
                         call_773829.route, valid.getOrDefault("path"))
  result = hook(call_773829, url, valid)

proc call*(call_773830: Call_GetCatalogImportStatus_773817; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_773831 = newJObject()
  if body != nil:
    body_773831 = body
  result = call_773830.call(nil, nil, nil, nil, body_773831)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_773817(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_773818, base: "/",
    url: url_GetCatalogImportStatus_773819, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_773832 = ref object of OpenApiRestCall_772597
proc url_GetClassifier_773834(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetClassifier_773833(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773835 = header.getOrDefault("X-Amz-Date")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Date", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Security-Token")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Security-Token", valid_773836
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773837 = header.getOrDefault("X-Amz-Target")
  valid_773837 = validateParameter(valid_773837, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_773837 != nil:
    section.add "X-Amz-Target", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Content-Sha256", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Algorithm")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Algorithm", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Signature")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Signature", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-SignedHeaders", valid_773841
  var valid_773842 = header.getOrDefault("X-Amz-Credential")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Credential", valid_773842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773844: Call_GetClassifier_773832; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_773844.validator(path, query, header, formData, body)
  let scheme = call_773844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773844.url(scheme.get, call_773844.host, call_773844.base,
                         call_773844.route, valid.getOrDefault("path"))
  result = hook(call_773844, url, valid)

proc call*(call_773845: Call_GetClassifier_773832; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_773846 = newJObject()
  if body != nil:
    body_773846 = body
  result = call_773845.call(nil, nil, nil, nil, body_773846)

var getClassifier* = Call_GetClassifier_773832(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_773833, base: "/", url: url_GetClassifier_773834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_773847 = ref object of OpenApiRestCall_772597
proc url_GetClassifiers_773849(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetClassifiers_773848(path: JsonNode; query: JsonNode;
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
  var valid_773850 = query.getOrDefault("NextToken")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "NextToken", valid_773850
  var valid_773851 = query.getOrDefault("MaxResults")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "MaxResults", valid_773851
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
  var valid_773852 = header.getOrDefault("X-Amz-Date")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Date", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Security-Token")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Security-Token", valid_773853
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773854 = header.getOrDefault("X-Amz-Target")
  valid_773854 = validateParameter(valid_773854, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_773854 != nil:
    section.add "X-Amz-Target", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Content-Sha256", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Algorithm")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Algorithm", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Signature")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Signature", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-SignedHeaders", valid_773858
  var valid_773859 = header.getOrDefault("X-Amz-Credential")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "X-Amz-Credential", valid_773859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773861: Call_GetClassifiers_773847; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_773861.validator(path, query, header, formData, body)
  let scheme = call_773861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773861.url(scheme.get, call_773861.host, call_773861.base,
                         call_773861.route, valid.getOrDefault("path"))
  result = hook(call_773861, url, valid)

proc call*(call_773862: Call_GetClassifiers_773847; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773863 = newJObject()
  var body_773864 = newJObject()
  add(query_773863, "NextToken", newJString(NextToken))
  if body != nil:
    body_773864 = body
  add(query_773863, "MaxResults", newJString(MaxResults))
  result = call_773862.call(nil, query_773863, nil, nil, body_773864)

var getClassifiers* = Call_GetClassifiers_773847(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_773848, base: "/", url: url_GetClassifiers_773849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_773866 = ref object of OpenApiRestCall_772597
proc url_GetConnection_773868(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConnection_773867(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773869 = header.getOrDefault("X-Amz-Date")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Date", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Security-Token")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Security-Token", valid_773870
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773871 = header.getOrDefault("X-Amz-Target")
  valid_773871 = validateParameter(valid_773871, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_773871 != nil:
    section.add "X-Amz-Target", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Content-Sha256", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Algorithm")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Algorithm", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-Signature")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-Signature", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-SignedHeaders", valid_773875
  var valid_773876 = header.getOrDefault("X-Amz-Credential")
  valid_773876 = validateParameter(valid_773876, JString, required = false,
                                 default = nil)
  if valid_773876 != nil:
    section.add "X-Amz-Credential", valid_773876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773878: Call_GetConnection_773866; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_773878.validator(path, query, header, formData, body)
  let scheme = call_773878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773878.url(scheme.get, call_773878.host, call_773878.base,
                         call_773878.route, valid.getOrDefault("path"))
  result = hook(call_773878, url, valid)

proc call*(call_773879: Call_GetConnection_773866; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_773880 = newJObject()
  if body != nil:
    body_773880 = body
  result = call_773879.call(nil, nil, nil, nil, body_773880)

var getConnection* = Call_GetConnection_773866(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_773867, base: "/", url: url_GetConnection_773868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_773881 = ref object of OpenApiRestCall_772597
proc url_GetConnections_773883(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConnections_773882(path: JsonNode; query: JsonNode;
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
  var valid_773884 = query.getOrDefault("NextToken")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "NextToken", valid_773884
  var valid_773885 = query.getOrDefault("MaxResults")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "MaxResults", valid_773885
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
  var valid_773886 = header.getOrDefault("X-Amz-Date")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-Date", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-Security-Token")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Security-Token", valid_773887
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773888 = header.getOrDefault("X-Amz-Target")
  valid_773888 = validateParameter(valid_773888, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_773888 != nil:
    section.add "X-Amz-Target", valid_773888
  var valid_773889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Content-Sha256", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Algorithm")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Algorithm", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Signature")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Signature", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-SignedHeaders", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Credential")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Credential", valid_773893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773895: Call_GetConnections_773881; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_773895.validator(path, query, header, formData, body)
  let scheme = call_773895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773895.url(scheme.get, call_773895.host, call_773895.base,
                         call_773895.route, valid.getOrDefault("path"))
  result = hook(call_773895, url, valid)

proc call*(call_773896: Call_GetConnections_773881; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773897 = newJObject()
  var body_773898 = newJObject()
  add(query_773897, "NextToken", newJString(NextToken))
  if body != nil:
    body_773898 = body
  add(query_773897, "MaxResults", newJString(MaxResults))
  result = call_773896.call(nil, query_773897, nil, nil, body_773898)

var getConnections* = Call_GetConnections_773881(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_773882, base: "/", url: url_GetConnections_773883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_773899 = ref object of OpenApiRestCall_772597
proc url_GetCrawler_773901(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCrawler_773900(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773902 = header.getOrDefault("X-Amz-Date")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Date", valid_773902
  var valid_773903 = header.getOrDefault("X-Amz-Security-Token")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Security-Token", valid_773903
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773904 = header.getOrDefault("X-Amz-Target")
  valid_773904 = validateParameter(valid_773904, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_773904 != nil:
    section.add "X-Amz-Target", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Content-Sha256", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Algorithm")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Algorithm", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-Signature")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Signature", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-SignedHeaders", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-Credential")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-Credential", valid_773909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773911: Call_GetCrawler_773899; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_773911.validator(path, query, header, formData, body)
  let scheme = call_773911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773911.url(scheme.get, call_773911.host, call_773911.base,
                         call_773911.route, valid.getOrDefault("path"))
  result = hook(call_773911, url, valid)

proc call*(call_773912: Call_GetCrawler_773899; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_773913 = newJObject()
  if body != nil:
    body_773913 = body
  result = call_773912.call(nil, nil, nil, nil, body_773913)

var getCrawler* = Call_GetCrawler_773899(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_773900,
                                      base: "/", url: url_GetCrawler_773901,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_773914 = ref object of OpenApiRestCall_772597
proc url_GetCrawlerMetrics_773916(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCrawlerMetrics_773915(path: JsonNode; query: JsonNode;
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
  var valid_773917 = query.getOrDefault("NextToken")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "NextToken", valid_773917
  var valid_773918 = query.getOrDefault("MaxResults")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "MaxResults", valid_773918
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
  var valid_773919 = header.getOrDefault("X-Amz-Date")
  valid_773919 = validateParameter(valid_773919, JString, required = false,
                                 default = nil)
  if valid_773919 != nil:
    section.add "X-Amz-Date", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-Security-Token")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-Security-Token", valid_773920
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773921 = header.getOrDefault("X-Amz-Target")
  valid_773921 = validateParameter(valid_773921, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_773921 != nil:
    section.add "X-Amz-Target", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Content-Sha256", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Algorithm")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Algorithm", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Signature")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Signature", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-SignedHeaders", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Credential")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Credential", valid_773926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773928: Call_GetCrawlerMetrics_773914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_773928.validator(path, query, header, formData, body)
  let scheme = call_773928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773928.url(scheme.get, call_773928.host, call_773928.base,
                         call_773928.route, valid.getOrDefault("path"))
  result = hook(call_773928, url, valid)

proc call*(call_773929: Call_GetCrawlerMetrics_773914; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773930 = newJObject()
  var body_773931 = newJObject()
  add(query_773930, "NextToken", newJString(NextToken))
  if body != nil:
    body_773931 = body
  add(query_773930, "MaxResults", newJString(MaxResults))
  result = call_773929.call(nil, query_773930, nil, nil, body_773931)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_773914(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_773915, base: "/",
    url: url_GetCrawlerMetrics_773916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_773932 = ref object of OpenApiRestCall_772597
proc url_GetCrawlers_773934(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCrawlers_773933(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773935 = query.getOrDefault("NextToken")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "NextToken", valid_773935
  var valid_773936 = query.getOrDefault("MaxResults")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "MaxResults", valid_773936
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
  var valid_773937 = header.getOrDefault("X-Amz-Date")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Date", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-Security-Token")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-Security-Token", valid_773938
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773939 = header.getOrDefault("X-Amz-Target")
  valid_773939 = validateParameter(valid_773939, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_773939 != nil:
    section.add "X-Amz-Target", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Content-Sha256", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-Algorithm")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Algorithm", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-Signature")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Signature", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-SignedHeaders", valid_773943
  var valid_773944 = header.getOrDefault("X-Amz-Credential")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "X-Amz-Credential", valid_773944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773946: Call_GetCrawlers_773932; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_773946.validator(path, query, header, formData, body)
  let scheme = call_773946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773946.url(scheme.get, call_773946.host, call_773946.base,
                         call_773946.route, valid.getOrDefault("path"))
  result = hook(call_773946, url, valid)

proc call*(call_773947: Call_GetCrawlers_773932; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773948 = newJObject()
  var body_773949 = newJObject()
  add(query_773948, "NextToken", newJString(NextToken))
  if body != nil:
    body_773949 = body
  add(query_773948, "MaxResults", newJString(MaxResults))
  result = call_773947.call(nil, query_773948, nil, nil, body_773949)

var getCrawlers* = Call_GetCrawlers_773932(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_773933,
                                        base: "/", url: url_GetCrawlers_773934,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_773950 = ref object of OpenApiRestCall_772597
proc url_GetDataCatalogEncryptionSettings_773952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDataCatalogEncryptionSettings_773951(path: JsonNode;
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
  var valid_773953 = header.getOrDefault("X-Amz-Date")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Date", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Security-Token")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Security-Token", valid_773954
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773955 = header.getOrDefault("X-Amz-Target")
  valid_773955 = validateParameter(valid_773955, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_773955 != nil:
    section.add "X-Amz-Target", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Content-Sha256", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Algorithm")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Algorithm", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-Signature")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-Signature", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-SignedHeaders", valid_773959
  var valid_773960 = header.getOrDefault("X-Amz-Credential")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-Credential", valid_773960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773962: Call_GetDataCatalogEncryptionSettings_773950;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_773962.validator(path, query, header, formData, body)
  let scheme = call_773962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773962.url(scheme.get, call_773962.host, call_773962.base,
                         call_773962.route, valid.getOrDefault("path"))
  result = hook(call_773962, url, valid)

proc call*(call_773963: Call_GetDataCatalogEncryptionSettings_773950;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_773964 = newJObject()
  if body != nil:
    body_773964 = body
  result = call_773963.call(nil, nil, nil, nil, body_773964)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_773950(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_773951, base: "/",
    url: url_GetDataCatalogEncryptionSettings_773952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_773965 = ref object of OpenApiRestCall_772597
proc url_GetDatabase_773967(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDatabase_773966(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773968 = header.getOrDefault("X-Amz-Date")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Date", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Security-Token")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Security-Token", valid_773969
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773970 = header.getOrDefault("X-Amz-Target")
  valid_773970 = validateParameter(valid_773970, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_773970 != nil:
    section.add "X-Amz-Target", valid_773970
  var valid_773971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773971 = validateParameter(valid_773971, JString, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "X-Amz-Content-Sha256", valid_773971
  var valid_773972 = header.getOrDefault("X-Amz-Algorithm")
  valid_773972 = validateParameter(valid_773972, JString, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "X-Amz-Algorithm", valid_773972
  var valid_773973 = header.getOrDefault("X-Amz-Signature")
  valid_773973 = validateParameter(valid_773973, JString, required = false,
                                 default = nil)
  if valid_773973 != nil:
    section.add "X-Amz-Signature", valid_773973
  var valid_773974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "X-Amz-SignedHeaders", valid_773974
  var valid_773975 = header.getOrDefault("X-Amz-Credential")
  valid_773975 = validateParameter(valid_773975, JString, required = false,
                                 default = nil)
  if valid_773975 != nil:
    section.add "X-Amz-Credential", valid_773975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773977: Call_GetDatabase_773965; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_773977.validator(path, query, header, formData, body)
  let scheme = call_773977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773977.url(scheme.get, call_773977.host, call_773977.base,
                         call_773977.route, valid.getOrDefault("path"))
  result = hook(call_773977, url, valid)

proc call*(call_773978: Call_GetDatabase_773965; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_773979 = newJObject()
  if body != nil:
    body_773979 = body
  result = call_773978.call(nil, nil, nil, nil, body_773979)

var getDatabase* = Call_GetDatabase_773965(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_773966,
                                        base: "/", url: url_GetDatabase_773967,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_773980 = ref object of OpenApiRestCall_772597
proc url_GetDatabases_773982(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDatabases_773981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773983 = query.getOrDefault("NextToken")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "NextToken", valid_773983
  var valid_773984 = query.getOrDefault("MaxResults")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "MaxResults", valid_773984
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
  var valid_773985 = header.getOrDefault("X-Amz-Date")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-Date", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-Security-Token")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Security-Token", valid_773986
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773987 = header.getOrDefault("X-Amz-Target")
  valid_773987 = validateParameter(valid_773987, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_773987 != nil:
    section.add "X-Amz-Target", valid_773987
  var valid_773988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "X-Amz-Content-Sha256", valid_773988
  var valid_773989 = header.getOrDefault("X-Amz-Algorithm")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Algorithm", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-Signature")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Signature", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-SignedHeaders", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Credential")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Credential", valid_773992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773994: Call_GetDatabases_773980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_773994.validator(path, query, header, formData, body)
  let scheme = call_773994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773994.url(scheme.get, call_773994.host, call_773994.base,
                         call_773994.route, valid.getOrDefault("path"))
  result = hook(call_773994, url, valid)

proc call*(call_773995: Call_GetDatabases_773980; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773996 = newJObject()
  var body_773997 = newJObject()
  add(query_773996, "NextToken", newJString(NextToken))
  if body != nil:
    body_773997 = body
  add(query_773996, "MaxResults", newJString(MaxResults))
  result = call_773995.call(nil, query_773996, nil, nil, body_773997)

var getDatabases* = Call_GetDatabases_773980(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_773981, base: "/", url: url_GetDatabases_773982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_773998 = ref object of OpenApiRestCall_772597
proc url_GetDataflowGraph_774000(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDataflowGraph_773999(path: JsonNode; query: JsonNode;
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
  var valid_774001 = header.getOrDefault("X-Amz-Date")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Date", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Security-Token")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Security-Token", valid_774002
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774003 = header.getOrDefault("X-Amz-Target")
  valid_774003 = validateParameter(valid_774003, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_774003 != nil:
    section.add "X-Amz-Target", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Content-Sha256", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-Algorithm")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Algorithm", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-Signature")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Signature", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-SignedHeaders", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Credential")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Credential", valid_774008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774010: Call_GetDataflowGraph_773998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_774010.validator(path, query, header, formData, body)
  let scheme = call_774010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774010.url(scheme.get, call_774010.host, call_774010.base,
                         call_774010.route, valid.getOrDefault("path"))
  result = hook(call_774010, url, valid)

proc call*(call_774011: Call_GetDataflowGraph_773998; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_774012 = newJObject()
  if body != nil:
    body_774012 = body
  result = call_774011.call(nil, nil, nil, nil, body_774012)

var getDataflowGraph* = Call_GetDataflowGraph_773998(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_773999, base: "/",
    url: url_GetDataflowGraph_774000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_774013 = ref object of OpenApiRestCall_772597
proc url_GetDevEndpoint_774015(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevEndpoint_774014(path: JsonNode; query: JsonNode;
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
  var valid_774016 = header.getOrDefault("X-Amz-Date")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-Date", valid_774016
  var valid_774017 = header.getOrDefault("X-Amz-Security-Token")
  valid_774017 = validateParameter(valid_774017, JString, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "X-Amz-Security-Token", valid_774017
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774018 = header.getOrDefault("X-Amz-Target")
  valid_774018 = validateParameter(valid_774018, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_774018 != nil:
    section.add "X-Amz-Target", valid_774018
  var valid_774019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "X-Amz-Content-Sha256", valid_774019
  var valid_774020 = header.getOrDefault("X-Amz-Algorithm")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "X-Amz-Algorithm", valid_774020
  var valid_774021 = header.getOrDefault("X-Amz-Signature")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "X-Amz-Signature", valid_774021
  var valid_774022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "X-Amz-SignedHeaders", valid_774022
  var valid_774023 = header.getOrDefault("X-Amz-Credential")
  valid_774023 = validateParameter(valid_774023, JString, required = false,
                                 default = nil)
  if valid_774023 != nil:
    section.add "X-Amz-Credential", valid_774023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774025: Call_GetDevEndpoint_774013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_774025.validator(path, query, header, formData, body)
  let scheme = call_774025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774025.url(scheme.get, call_774025.host, call_774025.base,
                         call_774025.route, valid.getOrDefault("path"))
  result = hook(call_774025, url, valid)

proc call*(call_774026: Call_GetDevEndpoint_774013; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_774027 = newJObject()
  if body != nil:
    body_774027 = body
  result = call_774026.call(nil, nil, nil, nil, body_774027)

var getDevEndpoint* = Call_GetDevEndpoint_774013(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_774014, base: "/", url: url_GetDevEndpoint_774015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_774028 = ref object of OpenApiRestCall_772597
proc url_GetDevEndpoints_774030(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDevEndpoints_774029(path: JsonNode; query: JsonNode;
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
  var valid_774031 = query.getOrDefault("NextToken")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "NextToken", valid_774031
  var valid_774032 = query.getOrDefault("MaxResults")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "MaxResults", valid_774032
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
  var valid_774033 = header.getOrDefault("X-Amz-Date")
  valid_774033 = validateParameter(valid_774033, JString, required = false,
                                 default = nil)
  if valid_774033 != nil:
    section.add "X-Amz-Date", valid_774033
  var valid_774034 = header.getOrDefault("X-Amz-Security-Token")
  valid_774034 = validateParameter(valid_774034, JString, required = false,
                                 default = nil)
  if valid_774034 != nil:
    section.add "X-Amz-Security-Token", valid_774034
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774035 = header.getOrDefault("X-Amz-Target")
  valid_774035 = validateParameter(valid_774035, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_774035 != nil:
    section.add "X-Amz-Target", valid_774035
  var valid_774036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "X-Amz-Content-Sha256", valid_774036
  var valid_774037 = header.getOrDefault("X-Amz-Algorithm")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Algorithm", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Signature")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Signature", valid_774038
  var valid_774039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-SignedHeaders", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Credential")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Credential", valid_774040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774042: Call_GetDevEndpoints_774028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_774042.validator(path, query, header, formData, body)
  let scheme = call_774042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774042.url(scheme.get, call_774042.host, call_774042.base,
                         call_774042.route, valid.getOrDefault("path"))
  result = hook(call_774042, url, valid)

proc call*(call_774043: Call_GetDevEndpoints_774028; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774044 = newJObject()
  var body_774045 = newJObject()
  add(query_774044, "NextToken", newJString(NextToken))
  if body != nil:
    body_774045 = body
  add(query_774044, "MaxResults", newJString(MaxResults))
  result = call_774043.call(nil, query_774044, nil, nil, body_774045)

var getDevEndpoints* = Call_GetDevEndpoints_774028(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_774029, base: "/", url: url_GetDevEndpoints_774030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_774046 = ref object of OpenApiRestCall_772597
proc url_GetJob_774048(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJob_774047(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774049 = header.getOrDefault("X-Amz-Date")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "X-Amz-Date", valid_774049
  var valid_774050 = header.getOrDefault("X-Amz-Security-Token")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "X-Amz-Security-Token", valid_774050
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774051 = header.getOrDefault("X-Amz-Target")
  valid_774051 = validateParameter(valid_774051, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_774051 != nil:
    section.add "X-Amz-Target", valid_774051
  var valid_774052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Content-Sha256", valid_774052
  var valid_774053 = header.getOrDefault("X-Amz-Algorithm")
  valid_774053 = validateParameter(valid_774053, JString, required = false,
                                 default = nil)
  if valid_774053 != nil:
    section.add "X-Amz-Algorithm", valid_774053
  var valid_774054 = header.getOrDefault("X-Amz-Signature")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "X-Amz-Signature", valid_774054
  var valid_774055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-SignedHeaders", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Credential")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Credential", valid_774056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774058: Call_GetJob_774046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_774058.validator(path, query, header, formData, body)
  let scheme = call_774058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774058.url(scheme.get, call_774058.host, call_774058.base,
                         call_774058.route, valid.getOrDefault("path"))
  result = hook(call_774058, url, valid)

proc call*(call_774059: Call_GetJob_774046; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_774060 = newJObject()
  if body != nil:
    body_774060 = body
  result = call_774059.call(nil, nil, nil, nil, body_774060)

var getJob* = Call_GetJob_774046(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_774047, base: "/",
                              url: url_GetJob_774048,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_774061 = ref object of OpenApiRestCall_772597
proc url_GetJobBookmark_774063(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJobBookmark_774062(path: JsonNode; query: JsonNode;
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
  var valid_774064 = header.getOrDefault("X-Amz-Date")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "X-Amz-Date", valid_774064
  var valid_774065 = header.getOrDefault("X-Amz-Security-Token")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Security-Token", valid_774065
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774066 = header.getOrDefault("X-Amz-Target")
  valid_774066 = validateParameter(valid_774066, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_774066 != nil:
    section.add "X-Amz-Target", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Content-Sha256", valid_774067
  var valid_774068 = header.getOrDefault("X-Amz-Algorithm")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "X-Amz-Algorithm", valid_774068
  var valid_774069 = header.getOrDefault("X-Amz-Signature")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Signature", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-SignedHeaders", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Credential")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Credential", valid_774071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774073: Call_GetJobBookmark_774061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_774073.validator(path, query, header, formData, body)
  let scheme = call_774073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774073.url(scheme.get, call_774073.host, call_774073.base,
                         call_774073.route, valid.getOrDefault("path"))
  result = hook(call_774073, url, valid)

proc call*(call_774074: Call_GetJobBookmark_774061; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_774075 = newJObject()
  if body != nil:
    body_774075 = body
  result = call_774074.call(nil, nil, nil, nil, body_774075)

var getJobBookmark* = Call_GetJobBookmark_774061(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_774062, base: "/", url: url_GetJobBookmark_774063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_774076 = ref object of OpenApiRestCall_772597
proc url_GetJobRun_774078(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJobRun_774077(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774079 = header.getOrDefault("X-Amz-Date")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Date", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Security-Token")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Security-Token", valid_774080
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774081 = header.getOrDefault("X-Amz-Target")
  valid_774081 = validateParameter(valid_774081, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_774081 != nil:
    section.add "X-Amz-Target", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Content-Sha256", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-Algorithm")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-Algorithm", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-Signature")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Signature", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-SignedHeaders", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Credential")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Credential", valid_774086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774088: Call_GetJobRun_774076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_774088.validator(path, query, header, formData, body)
  let scheme = call_774088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774088.url(scheme.get, call_774088.host, call_774088.base,
                         call_774088.route, valid.getOrDefault("path"))
  result = hook(call_774088, url, valid)

proc call*(call_774089: Call_GetJobRun_774076; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_774090 = newJObject()
  if body != nil:
    body_774090 = body
  result = call_774089.call(nil, nil, nil, nil, body_774090)

var getJobRun* = Call_GetJobRun_774076(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_774077,
                                    base: "/", url: url_GetJobRun_774078,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_774091 = ref object of OpenApiRestCall_772597
proc url_GetJobRuns_774093(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJobRuns_774092(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774094 = query.getOrDefault("NextToken")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "NextToken", valid_774094
  var valid_774095 = query.getOrDefault("MaxResults")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "MaxResults", valid_774095
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
  var valid_774096 = header.getOrDefault("X-Amz-Date")
  valid_774096 = validateParameter(valid_774096, JString, required = false,
                                 default = nil)
  if valid_774096 != nil:
    section.add "X-Amz-Date", valid_774096
  var valid_774097 = header.getOrDefault("X-Amz-Security-Token")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "X-Amz-Security-Token", valid_774097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774098 = header.getOrDefault("X-Amz-Target")
  valid_774098 = validateParameter(valid_774098, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_774098 != nil:
    section.add "X-Amz-Target", valid_774098
  var valid_774099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Content-Sha256", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Algorithm")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Algorithm", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Signature")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Signature", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-SignedHeaders", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-Credential")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-Credential", valid_774103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774105: Call_GetJobRuns_774091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_774105.validator(path, query, header, formData, body)
  let scheme = call_774105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774105.url(scheme.get, call_774105.host, call_774105.base,
                         call_774105.route, valid.getOrDefault("path"))
  result = hook(call_774105, url, valid)

proc call*(call_774106: Call_GetJobRuns_774091; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774107 = newJObject()
  var body_774108 = newJObject()
  add(query_774107, "NextToken", newJString(NextToken))
  if body != nil:
    body_774108 = body
  add(query_774107, "MaxResults", newJString(MaxResults))
  result = call_774106.call(nil, query_774107, nil, nil, body_774108)

var getJobRuns* = Call_GetJobRuns_774091(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_774092,
                                      base: "/", url: url_GetJobRuns_774093,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_774109 = ref object of OpenApiRestCall_772597
proc url_GetJobs_774111(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJobs_774110(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774112 = query.getOrDefault("NextToken")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "NextToken", valid_774112
  var valid_774113 = query.getOrDefault("MaxResults")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "MaxResults", valid_774113
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
  var valid_774114 = header.getOrDefault("X-Amz-Date")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Date", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Security-Token")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Security-Token", valid_774115
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774116 = header.getOrDefault("X-Amz-Target")
  valid_774116 = validateParameter(valid_774116, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_774116 != nil:
    section.add "X-Amz-Target", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Content-Sha256", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Algorithm")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Algorithm", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Signature")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Signature", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-SignedHeaders", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-Credential")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-Credential", valid_774121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774123: Call_GetJobs_774109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_774123.validator(path, query, header, formData, body)
  let scheme = call_774123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774123.url(scheme.get, call_774123.host, call_774123.base,
                         call_774123.route, valid.getOrDefault("path"))
  result = hook(call_774123, url, valid)

proc call*(call_774124: Call_GetJobs_774109; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774125 = newJObject()
  var body_774126 = newJObject()
  add(query_774125, "NextToken", newJString(NextToken))
  if body != nil:
    body_774126 = body
  add(query_774125, "MaxResults", newJString(MaxResults))
  result = call_774124.call(nil, query_774125, nil, nil, body_774126)

var getJobs* = Call_GetJobs_774109(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_774110, base: "/",
                                url: url_GetJobs_774111,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_774127 = ref object of OpenApiRestCall_772597
proc url_GetMLTaskRun_774129(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMLTaskRun_774128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774130 = header.getOrDefault("X-Amz-Date")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Date", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-Security-Token")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Security-Token", valid_774131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774132 = header.getOrDefault("X-Amz-Target")
  valid_774132 = validateParameter(valid_774132, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_774132 != nil:
    section.add "X-Amz-Target", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Content-Sha256", valid_774133
  var valid_774134 = header.getOrDefault("X-Amz-Algorithm")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Algorithm", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Signature")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Signature", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-SignedHeaders", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Credential")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Credential", valid_774137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774139: Call_GetMLTaskRun_774127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_774139.validator(path, query, header, formData, body)
  let scheme = call_774139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774139.url(scheme.get, call_774139.host, call_774139.base,
                         call_774139.route, valid.getOrDefault("path"))
  result = hook(call_774139, url, valid)

proc call*(call_774140: Call_GetMLTaskRun_774127; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_774141 = newJObject()
  if body != nil:
    body_774141 = body
  result = call_774140.call(nil, nil, nil, nil, body_774141)

var getMLTaskRun* = Call_GetMLTaskRun_774127(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_774128, base: "/", url: url_GetMLTaskRun_774129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_774142 = ref object of OpenApiRestCall_772597
proc url_GetMLTaskRuns_774144(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMLTaskRuns_774143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774145 = query.getOrDefault("NextToken")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "NextToken", valid_774145
  var valid_774146 = query.getOrDefault("MaxResults")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "MaxResults", valid_774146
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
  var valid_774147 = header.getOrDefault("X-Amz-Date")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "X-Amz-Date", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-Security-Token")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-Security-Token", valid_774148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774149 = header.getOrDefault("X-Amz-Target")
  valid_774149 = validateParameter(valid_774149, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_774149 != nil:
    section.add "X-Amz-Target", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Content-Sha256", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-Algorithm")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Algorithm", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Signature")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Signature", valid_774152
  var valid_774153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-SignedHeaders", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-Credential")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-Credential", valid_774154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774156: Call_GetMLTaskRuns_774142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_774156.validator(path, query, header, formData, body)
  let scheme = call_774156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774156.url(scheme.get, call_774156.host, call_774156.base,
                         call_774156.route, valid.getOrDefault("path"))
  result = hook(call_774156, url, valid)

proc call*(call_774157: Call_GetMLTaskRuns_774142; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774158 = newJObject()
  var body_774159 = newJObject()
  add(query_774158, "NextToken", newJString(NextToken))
  if body != nil:
    body_774159 = body
  add(query_774158, "MaxResults", newJString(MaxResults))
  result = call_774157.call(nil, query_774158, nil, nil, body_774159)

var getMLTaskRuns* = Call_GetMLTaskRuns_774142(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_774143, base: "/", url: url_GetMLTaskRuns_774144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_774160 = ref object of OpenApiRestCall_772597
proc url_GetMLTransform_774162(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMLTransform_774161(path: JsonNode; query: JsonNode;
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
  var valid_774163 = header.getOrDefault("X-Amz-Date")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-Date", valid_774163
  var valid_774164 = header.getOrDefault("X-Amz-Security-Token")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-Security-Token", valid_774164
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774165 = header.getOrDefault("X-Amz-Target")
  valid_774165 = validateParameter(valid_774165, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_774165 != nil:
    section.add "X-Amz-Target", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Content-Sha256", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-Algorithm")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-Algorithm", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-Signature")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Signature", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-SignedHeaders", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Credential")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Credential", valid_774170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774172: Call_GetMLTransform_774160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_774172.validator(path, query, header, formData, body)
  let scheme = call_774172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774172.url(scheme.get, call_774172.host, call_774172.base,
                         call_774172.route, valid.getOrDefault("path"))
  result = hook(call_774172, url, valid)

proc call*(call_774173: Call_GetMLTransform_774160; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_774174 = newJObject()
  if body != nil:
    body_774174 = body
  result = call_774173.call(nil, nil, nil, nil, body_774174)

var getMLTransform* = Call_GetMLTransform_774160(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_774161, base: "/", url: url_GetMLTransform_774162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_774175 = ref object of OpenApiRestCall_772597
proc url_GetMLTransforms_774177(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMLTransforms_774176(path: JsonNode; query: JsonNode;
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
  var valid_774178 = query.getOrDefault("NextToken")
  valid_774178 = validateParameter(valid_774178, JString, required = false,
                                 default = nil)
  if valid_774178 != nil:
    section.add "NextToken", valid_774178
  var valid_774179 = query.getOrDefault("MaxResults")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "MaxResults", valid_774179
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
  var valid_774180 = header.getOrDefault("X-Amz-Date")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "X-Amz-Date", valid_774180
  var valid_774181 = header.getOrDefault("X-Amz-Security-Token")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "X-Amz-Security-Token", valid_774181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774182 = header.getOrDefault("X-Amz-Target")
  valid_774182 = validateParameter(valid_774182, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_774182 != nil:
    section.add "X-Amz-Target", valid_774182
  var valid_774183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "X-Amz-Content-Sha256", valid_774183
  var valid_774184 = header.getOrDefault("X-Amz-Algorithm")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "X-Amz-Algorithm", valid_774184
  var valid_774185 = header.getOrDefault("X-Amz-Signature")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "X-Amz-Signature", valid_774185
  var valid_774186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "X-Amz-SignedHeaders", valid_774186
  var valid_774187 = header.getOrDefault("X-Amz-Credential")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-Credential", valid_774187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774189: Call_GetMLTransforms_774175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_774189.validator(path, query, header, formData, body)
  let scheme = call_774189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774189.url(scheme.get, call_774189.host, call_774189.base,
                         call_774189.route, valid.getOrDefault("path"))
  result = hook(call_774189, url, valid)

proc call*(call_774190: Call_GetMLTransforms_774175; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774191 = newJObject()
  var body_774192 = newJObject()
  add(query_774191, "NextToken", newJString(NextToken))
  if body != nil:
    body_774192 = body
  add(query_774191, "MaxResults", newJString(MaxResults))
  result = call_774190.call(nil, query_774191, nil, nil, body_774192)

var getMLTransforms* = Call_GetMLTransforms_774175(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_774176, base: "/", url: url_GetMLTransforms_774177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_774193 = ref object of OpenApiRestCall_772597
proc url_GetMapping_774195(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMapping_774194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774196 = header.getOrDefault("X-Amz-Date")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-Date", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Security-Token")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Security-Token", valid_774197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774198 = header.getOrDefault("X-Amz-Target")
  valid_774198 = validateParameter(valid_774198, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_774198 != nil:
    section.add "X-Amz-Target", valid_774198
  var valid_774199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "X-Amz-Content-Sha256", valid_774199
  var valid_774200 = header.getOrDefault("X-Amz-Algorithm")
  valid_774200 = validateParameter(valid_774200, JString, required = false,
                                 default = nil)
  if valid_774200 != nil:
    section.add "X-Amz-Algorithm", valid_774200
  var valid_774201 = header.getOrDefault("X-Amz-Signature")
  valid_774201 = validateParameter(valid_774201, JString, required = false,
                                 default = nil)
  if valid_774201 != nil:
    section.add "X-Amz-Signature", valid_774201
  var valid_774202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-SignedHeaders", valid_774202
  var valid_774203 = header.getOrDefault("X-Amz-Credential")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Credential", valid_774203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774205: Call_GetMapping_774193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_774205.validator(path, query, header, formData, body)
  let scheme = call_774205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774205.url(scheme.get, call_774205.host, call_774205.base,
                         call_774205.route, valid.getOrDefault("path"))
  result = hook(call_774205, url, valid)

proc call*(call_774206: Call_GetMapping_774193; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_774207 = newJObject()
  if body != nil:
    body_774207 = body
  result = call_774206.call(nil, nil, nil, nil, body_774207)

var getMapping* = Call_GetMapping_774193(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_774194,
                                      base: "/", url: url_GetMapping_774195,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_774208 = ref object of OpenApiRestCall_772597
proc url_GetPartition_774210(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPartition_774209(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774211 = header.getOrDefault("X-Amz-Date")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-Date", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Security-Token")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Security-Token", valid_774212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774213 = header.getOrDefault("X-Amz-Target")
  valid_774213 = validateParameter(valid_774213, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_774213 != nil:
    section.add "X-Amz-Target", valid_774213
  var valid_774214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "X-Amz-Content-Sha256", valid_774214
  var valid_774215 = header.getOrDefault("X-Amz-Algorithm")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "X-Amz-Algorithm", valid_774215
  var valid_774216 = header.getOrDefault("X-Amz-Signature")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "X-Amz-Signature", valid_774216
  var valid_774217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "X-Amz-SignedHeaders", valid_774217
  var valid_774218 = header.getOrDefault("X-Amz-Credential")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "X-Amz-Credential", valid_774218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774220: Call_GetPartition_774208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_774220.validator(path, query, header, formData, body)
  let scheme = call_774220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774220.url(scheme.get, call_774220.host, call_774220.base,
                         call_774220.route, valid.getOrDefault("path"))
  result = hook(call_774220, url, valid)

proc call*(call_774221: Call_GetPartition_774208; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_774222 = newJObject()
  if body != nil:
    body_774222 = body
  result = call_774221.call(nil, nil, nil, nil, body_774222)

var getPartition* = Call_GetPartition_774208(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_774209, base: "/", url: url_GetPartition_774210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_774223 = ref object of OpenApiRestCall_772597
proc url_GetPartitions_774225(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPartitions_774224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774226 = query.getOrDefault("NextToken")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "NextToken", valid_774226
  var valid_774227 = query.getOrDefault("MaxResults")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "MaxResults", valid_774227
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
  var valid_774228 = header.getOrDefault("X-Amz-Date")
  valid_774228 = validateParameter(valid_774228, JString, required = false,
                                 default = nil)
  if valid_774228 != nil:
    section.add "X-Amz-Date", valid_774228
  var valid_774229 = header.getOrDefault("X-Amz-Security-Token")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "X-Amz-Security-Token", valid_774229
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774230 = header.getOrDefault("X-Amz-Target")
  valid_774230 = validateParameter(valid_774230, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_774230 != nil:
    section.add "X-Amz-Target", valid_774230
  var valid_774231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774231 = validateParameter(valid_774231, JString, required = false,
                                 default = nil)
  if valid_774231 != nil:
    section.add "X-Amz-Content-Sha256", valid_774231
  var valid_774232 = header.getOrDefault("X-Amz-Algorithm")
  valid_774232 = validateParameter(valid_774232, JString, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "X-Amz-Algorithm", valid_774232
  var valid_774233 = header.getOrDefault("X-Amz-Signature")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "X-Amz-Signature", valid_774233
  var valid_774234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = nil)
  if valid_774234 != nil:
    section.add "X-Amz-SignedHeaders", valid_774234
  var valid_774235 = header.getOrDefault("X-Amz-Credential")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Credential", valid_774235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774237: Call_GetPartitions_774223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_774237.validator(path, query, header, formData, body)
  let scheme = call_774237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774237.url(scheme.get, call_774237.host, call_774237.base,
                         call_774237.route, valid.getOrDefault("path"))
  result = hook(call_774237, url, valid)

proc call*(call_774238: Call_GetPartitions_774223; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774239 = newJObject()
  var body_774240 = newJObject()
  add(query_774239, "NextToken", newJString(NextToken))
  if body != nil:
    body_774240 = body
  add(query_774239, "MaxResults", newJString(MaxResults))
  result = call_774238.call(nil, query_774239, nil, nil, body_774240)

var getPartitions* = Call_GetPartitions_774223(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_774224, base: "/", url: url_GetPartitions_774225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_774241 = ref object of OpenApiRestCall_772597
proc url_GetPlan_774243(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPlan_774242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774244 = header.getOrDefault("X-Amz-Date")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Date", valid_774244
  var valid_774245 = header.getOrDefault("X-Amz-Security-Token")
  valid_774245 = validateParameter(valid_774245, JString, required = false,
                                 default = nil)
  if valid_774245 != nil:
    section.add "X-Amz-Security-Token", valid_774245
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774246 = header.getOrDefault("X-Amz-Target")
  valid_774246 = validateParameter(valid_774246, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_774246 != nil:
    section.add "X-Amz-Target", valid_774246
  var valid_774247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774247 = validateParameter(valid_774247, JString, required = false,
                                 default = nil)
  if valid_774247 != nil:
    section.add "X-Amz-Content-Sha256", valid_774247
  var valid_774248 = header.getOrDefault("X-Amz-Algorithm")
  valid_774248 = validateParameter(valid_774248, JString, required = false,
                                 default = nil)
  if valid_774248 != nil:
    section.add "X-Amz-Algorithm", valid_774248
  var valid_774249 = header.getOrDefault("X-Amz-Signature")
  valid_774249 = validateParameter(valid_774249, JString, required = false,
                                 default = nil)
  if valid_774249 != nil:
    section.add "X-Amz-Signature", valid_774249
  var valid_774250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-SignedHeaders", valid_774250
  var valid_774251 = header.getOrDefault("X-Amz-Credential")
  valid_774251 = validateParameter(valid_774251, JString, required = false,
                                 default = nil)
  if valid_774251 != nil:
    section.add "X-Amz-Credential", valid_774251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774253: Call_GetPlan_774241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_774253.validator(path, query, header, formData, body)
  let scheme = call_774253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774253.url(scheme.get, call_774253.host, call_774253.base,
                         call_774253.route, valid.getOrDefault("path"))
  result = hook(call_774253, url, valid)

proc call*(call_774254: Call_GetPlan_774241; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_774255 = newJObject()
  if body != nil:
    body_774255 = body
  result = call_774254.call(nil, nil, nil, nil, body_774255)

var getPlan* = Call_GetPlan_774241(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_774242, base: "/",
                                url: url_GetPlan_774243,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_774256 = ref object of OpenApiRestCall_772597
proc url_GetResourcePolicy_774258(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourcePolicy_774257(path: JsonNode; query: JsonNode;
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
  var valid_774259 = header.getOrDefault("X-Amz-Date")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "X-Amz-Date", valid_774259
  var valid_774260 = header.getOrDefault("X-Amz-Security-Token")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "X-Amz-Security-Token", valid_774260
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774261 = header.getOrDefault("X-Amz-Target")
  valid_774261 = validateParameter(valid_774261, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_774261 != nil:
    section.add "X-Amz-Target", valid_774261
  var valid_774262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774262 = validateParameter(valid_774262, JString, required = false,
                                 default = nil)
  if valid_774262 != nil:
    section.add "X-Amz-Content-Sha256", valid_774262
  var valid_774263 = header.getOrDefault("X-Amz-Algorithm")
  valid_774263 = validateParameter(valid_774263, JString, required = false,
                                 default = nil)
  if valid_774263 != nil:
    section.add "X-Amz-Algorithm", valid_774263
  var valid_774264 = header.getOrDefault("X-Amz-Signature")
  valid_774264 = validateParameter(valid_774264, JString, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "X-Amz-Signature", valid_774264
  var valid_774265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774265 = validateParameter(valid_774265, JString, required = false,
                                 default = nil)
  if valid_774265 != nil:
    section.add "X-Amz-SignedHeaders", valid_774265
  var valid_774266 = header.getOrDefault("X-Amz-Credential")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "X-Amz-Credential", valid_774266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774268: Call_GetResourcePolicy_774256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_774268.validator(path, query, header, formData, body)
  let scheme = call_774268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774268.url(scheme.get, call_774268.host, call_774268.base,
                         call_774268.route, valid.getOrDefault("path"))
  result = hook(call_774268, url, valid)

proc call*(call_774269: Call_GetResourcePolicy_774256; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_774270 = newJObject()
  if body != nil:
    body_774270 = body
  result = call_774269.call(nil, nil, nil, nil, body_774270)

var getResourcePolicy* = Call_GetResourcePolicy_774256(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_774257, base: "/",
    url: url_GetResourcePolicy_774258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_774271 = ref object of OpenApiRestCall_772597
proc url_GetSecurityConfiguration_774273(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSecurityConfiguration_774272(path: JsonNode; query: JsonNode;
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
  var valid_774274 = header.getOrDefault("X-Amz-Date")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Date", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-Security-Token")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-Security-Token", valid_774275
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774276 = header.getOrDefault("X-Amz-Target")
  valid_774276 = validateParameter(valid_774276, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_774276 != nil:
    section.add "X-Amz-Target", valid_774276
  var valid_774277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "X-Amz-Content-Sha256", valid_774277
  var valid_774278 = header.getOrDefault("X-Amz-Algorithm")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-Algorithm", valid_774278
  var valid_774279 = header.getOrDefault("X-Amz-Signature")
  valid_774279 = validateParameter(valid_774279, JString, required = false,
                                 default = nil)
  if valid_774279 != nil:
    section.add "X-Amz-Signature", valid_774279
  var valid_774280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "X-Amz-SignedHeaders", valid_774280
  var valid_774281 = header.getOrDefault("X-Amz-Credential")
  valid_774281 = validateParameter(valid_774281, JString, required = false,
                                 default = nil)
  if valid_774281 != nil:
    section.add "X-Amz-Credential", valid_774281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774283: Call_GetSecurityConfiguration_774271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_774283.validator(path, query, header, formData, body)
  let scheme = call_774283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774283.url(scheme.get, call_774283.host, call_774283.base,
                         call_774283.route, valid.getOrDefault("path"))
  result = hook(call_774283, url, valid)

proc call*(call_774284: Call_GetSecurityConfiguration_774271; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_774285 = newJObject()
  if body != nil:
    body_774285 = body
  result = call_774284.call(nil, nil, nil, nil, body_774285)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_774271(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_774272, base: "/",
    url: url_GetSecurityConfiguration_774273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_774286 = ref object of OpenApiRestCall_772597
proc url_GetSecurityConfigurations_774288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSecurityConfigurations_774287(path: JsonNode; query: JsonNode;
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
  var valid_774289 = query.getOrDefault("NextToken")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "NextToken", valid_774289
  var valid_774290 = query.getOrDefault("MaxResults")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "MaxResults", valid_774290
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
  var valid_774291 = header.getOrDefault("X-Amz-Date")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "X-Amz-Date", valid_774291
  var valid_774292 = header.getOrDefault("X-Amz-Security-Token")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "X-Amz-Security-Token", valid_774292
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774293 = header.getOrDefault("X-Amz-Target")
  valid_774293 = validateParameter(valid_774293, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_774293 != nil:
    section.add "X-Amz-Target", valid_774293
  var valid_774294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774294 = validateParameter(valid_774294, JString, required = false,
                                 default = nil)
  if valid_774294 != nil:
    section.add "X-Amz-Content-Sha256", valid_774294
  var valid_774295 = header.getOrDefault("X-Amz-Algorithm")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "X-Amz-Algorithm", valid_774295
  var valid_774296 = header.getOrDefault("X-Amz-Signature")
  valid_774296 = validateParameter(valid_774296, JString, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "X-Amz-Signature", valid_774296
  var valid_774297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774297 = validateParameter(valid_774297, JString, required = false,
                                 default = nil)
  if valid_774297 != nil:
    section.add "X-Amz-SignedHeaders", valid_774297
  var valid_774298 = header.getOrDefault("X-Amz-Credential")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "X-Amz-Credential", valid_774298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774300: Call_GetSecurityConfigurations_774286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_774300.validator(path, query, header, formData, body)
  let scheme = call_774300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774300.url(scheme.get, call_774300.host, call_774300.base,
                         call_774300.route, valid.getOrDefault("path"))
  result = hook(call_774300, url, valid)

proc call*(call_774301: Call_GetSecurityConfigurations_774286; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774302 = newJObject()
  var body_774303 = newJObject()
  add(query_774302, "NextToken", newJString(NextToken))
  if body != nil:
    body_774303 = body
  add(query_774302, "MaxResults", newJString(MaxResults))
  result = call_774301.call(nil, query_774302, nil, nil, body_774303)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_774286(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_774287, base: "/",
    url: url_GetSecurityConfigurations_774288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_774304 = ref object of OpenApiRestCall_772597
proc url_GetTable_774306(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTable_774305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774307 = header.getOrDefault("X-Amz-Date")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Date", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-Security-Token")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-Security-Token", valid_774308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774309 = header.getOrDefault("X-Amz-Target")
  valid_774309 = validateParameter(valid_774309, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_774309 != nil:
    section.add "X-Amz-Target", valid_774309
  var valid_774310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "X-Amz-Content-Sha256", valid_774310
  var valid_774311 = header.getOrDefault("X-Amz-Algorithm")
  valid_774311 = validateParameter(valid_774311, JString, required = false,
                                 default = nil)
  if valid_774311 != nil:
    section.add "X-Amz-Algorithm", valid_774311
  var valid_774312 = header.getOrDefault("X-Amz-Signature")
  valid_774312 = validateParameter(valid_774312, JString, required = false,
                                 default = nil)
  if valid_774312 != nil:
    section.add "X-Amz-Signature", valid_774312
  var valid_774313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "X-Amz-SignedHeaders", valid_774313
  var valid_774314 = header.getOrDefault("X-Amz-Credential")
  valid_774314 = validateParameter(valid_774314, JString, required = false,
                                 default = nil)
  if valid_774314 != nil:
    section.add "X-Amz-Credential", valid_774314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774316: Call_GetTable_774304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_774316.validator(path, query, header, formData, body)
  let scheme = call_774316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774316.url(scheme.get, call_774316.host, call_774316.base,
                         call_774316.route, valid.getOrDefault("path"))
  result = hook(call_774316, url, valid)

proc call*(call_774317: Call_GetTable_774304; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_774318 = newJObject()
  if body != nil:
    body_774318 = body
  result = call_774317.call(nil, nil, nil, nil, body_774318)

var getTable* = Call_GetTable_774304(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_774305, base: "/",
                                  url: url_GetTable_774306,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_774319 = ref object of OpenApiRestCall_772597
proc url_GetTableVersion_774321(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTableVersion_774320(path: JsonNode; query: JsonNode;
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
  var valid_774322 = header.getOrDefault("X-Amz-Date")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Date", valid_774322
  var valid_774323 = header.getOrDefault("X-Amz-Security-Token")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "X-Amz-Security-Token", valid_774323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774324 = header.getOrDefault("X-Amz-Target")
  valid_774324 = validateParameter(valid_774324, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_774324 != nil:
    section.add "X-Amz-Target", valid_774324
  var valid_774325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "X-Amz-Content-Sha256", valid_774325
  var valid_774326 = header.getOrDefault("X-Amz-Algorithm")
  valid_774326 = validateParameter(valid_774326, JString, required = false,
                                 default = nil)
  if valid_774326 != nil:
    section.add "X-Amz-Algorithm", valid_774326
  var valid_774327 = header.getOrDefault("X-Amz-Signature")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "X-Amz-Signature", valid_774327
  var valid_774328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "X-Amz-SignedHeaders", valid_774328
  var valid_774329 = header.getOrDefault("X-Amz-Credential")
  valid_774329 = validateParameter(valid_774329, JString, required = false,
                                 default = nil)
  if valid_774329 != nil:
    section.add "X-Amz-Credential", valid_774329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774331: Call_GetTableVersion_774319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_774331.validator(path, query, header, formData, body)
  let scheme = call_774331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774331.url(scheme.get, call_774331.host, call_774331.base,
                         call_774331.route, valid.getOrDefault("path"))
  result = hook(call_774331, url, valid)

proc call*(call_774332: Call_GetTableVersion_774319; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_774333 = newJObject()
  if body != nil:
    body_774333 = body
  result = call_774332.call(nil, nil, nil, nil, body_774333)

var getTableVersion* = Call_GetTableVersion_774319(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_774320, base: "/", url: url_GetTableVersion_774321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_774334 = ref object of OpenApiRestCall_772597
proc url_GetTableVersions_774336(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTableVersions_774335(path: JsonNode; query: JsonNode;
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
  var valid_774337 = query.getOrDefault("NextToken")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "NextToken", valid_774337
  var valid_774338 = query.getOrDefault("MaxResults")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "MaxResults", valid_774338
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
  var valid_774339 = header.getOrDefault("X-Amz-Date")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "X-Amz-Date", valid_774339
  var valid_774340 = header.getOrDefault("X-Amz-Security-Token")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "X-Amz-Security-Token", valid_774340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774341 = header.getOrDefault("X-Amz-Target")
  valid_774341 = validateParameter(valid_774341, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_774341 != nil:
    section.add "X-Amz-Target", valid_774341
  var valid_774342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Content-Sha256", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-Algorithm")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-Algorithm", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Signature")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Signature", valid_774344
  var valid_774345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "X-Amz-SignedHeaders", valid_774345
  var valid_774346 = header.getOrDefault("X-Amz-Credential")
  valid_774346 = validateParameter(valid_774346, JString, required = false,
                                 default = nil)
  if valid_774346 != nil:
    section.add "X-Amz-Credential", valid_774346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774348: Call_GetTableVersions_774334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_774348.validator(path, query, header, formData, body)
  let scheme = call_774348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774348.url(scheme.get, call_774348.host, call_774348.base,
                         call_774348.route, valid.getOrDefault("path"))
  result = hook(call_774348, url, valid)

proc call*(call_774349: Call_GetTableVersions_774334; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774350 = newJObject()
  var body_774351 = newJObject()
  add(query_774350, "NextToken", newJString(NextToken))
  if body != nil:
    body_774351 = body
  add(query_774350, "MaxResults", newJString(MaxResults))
  result = call_774349.call(nil, query_774350, nil, nil, body_774351)

var getTableVersions* = Call_GetTableVersions_774334(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_774335, base: "/",
    url: url_GetTableVersions_774336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_774352 = ref object of OpenApiRestCall_772597
proc url_GetTables_774354(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTables_774353(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774355 = query.getOrDefault("NextToken")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "NextToken", valid_774355
  var valid_774356 = query.getOrDefault("MaxResults")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "MaxResults", valid_774356
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
  var valid_774357 = header.getOrDefault("X-Amz-Date")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Date", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Security-Token")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Security-Token", valid_774358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774359 = header.getOrDefault("X-Amz-Target")
  valid_774359 = validateParameter(valid_774359, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_774359 != nil:
    section.add "X-Amz-Target", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-Content-Sha256", valid_774360
  var valid_774361 = header.getOrDefault("X-Amz-Algorithm")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Algorithm", valid_774361
  var valid_774362 = header.getOrDefault("X-Amz-Signature")
  valid_774362 = validateParameter(valid_774362, JString, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "X-Amz-Signature", valid_774362
  var valid_774363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774363 = validateParameter(valid_774363, JString, required = false,
                                 default = nil)
  if valid_774363 != nil:
    section.add "X-Amz-SignedHeaders", valid_774363
  var valid_774364 = header.getOrDefault("X-Amz-Credential")
  valid_774364 = validateParameter(valid_774364, JString, required = false,
                                 default = nil)
  if valid_774364 != nil:
    section.add "X-Amz-Credential", valid_774364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774366: Call_GetTables_774352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_774366.validator(path, query, header, formData, body)
  let scheme = call_774366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774366.url(scheme.get, call_774366.host, call_774366.base,
                         call_774366.route, valid.getOrDefault("path"))
  result = hook(call_774366, url, valid)

proc call*(call_774367: Call_GetTables_774352; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774368 = newJObject()
  var body_774369 = newJObject()
  add(query_774368, "NextToken", newJString(NextToken))
  if body != nil:
    body_774369 = body
  add(query_774368, "MaxResults", newJString(MaxResults))
  result = call_774367.call(nil, query_774368, nil, nil, body_774369)

var getTables* = Call_GetTables_774352(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_774353,
                                    base: "/", url: url_GetTables_774354,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_774370 = ref object of OpenApiRestCall_772597
proc url_GetTags_774372(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTags_774371(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774373 = header.getOrDefault("X-Amz-Date")
  valid_774373 = validateParameter(valid_774373, JString, required = false,
                                 default = nil)
  if valid_774373 != nil:
    section.add "X-Amz-Date", valid_774373
  var valid_774374 = header.getOrDefault("X-Amz-Security-Token")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-Security-Token", valid_774374
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774375 = header.getOrDefault("X-Amz-Target")
  valid_774375 = validateParameter(valid_774375, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_774375 != nil:
    section.add "X-Amz-Target", valid_774375
  var valid_774376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Content-Sha256", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-Algorithm")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-Algorithm", valid_774377
  var valid_774378 = header.getOrDefault("X-Amz-Signature")
  valid_774378 = validateParameter(valid_774378, JString, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "X-Amz-Signature", valid_774378
  var valid_774379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "X-Amz-SignedHeaders", valid_774379
  var valid_774380 = header.getOrDefault("X-Amz-Credential")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "X-Amz-Credential", valid_774380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774382: Call_GetTags_774370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_774382.validator(path, query, header, formData, body)
  let scheme = call_774382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774382.url(scheme.get, call_774382.host, call_774382.base,
                         call_774382.route, valid.getOrDefault("path"))
  result = hook(call_774382, url, valid)

proc call*(call_774383: Call_GetTags_774370; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_774384 = newJObject()
  if body != nil:
    body_774384 = body
  result = call_774383.call(nil, nil, nil, nil, body_774384)

var getTags* = Call_GetTags_774370(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_774371, base: "/",
                                url: url_GetTags_774372,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_774385 = ref object of OpenApiRestCall_772597
proc url_GetTrigger_774387(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTrigger_774386(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774388 = header.getOrDefault("X-Amz-Date")
  valid_774388 = validateParameter(valid_774388, JString, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "X-Amz-Date", valid_774388
  var valid_774389 = header.getOrDefault("X-Amz-Security-Token")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Security-Token", valid_774389
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774390 = header.getOrDefault("X-Amz-Target")
  valid_774390 = validateParameter(valid_774390, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_774390 != nil:
    section.add "X-Amz-Target", valid_774390
  var valid_774391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-Content-Sha256", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Algorithm")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Algorithm", valid_774392
  var valid_774393 = header.getOrDefault("X-Amz-Signature")
  valid_774393 = validateParameter(valid_774393, JString, required = false,
                                 default = nil)
  if valid_774393 != nil:
    section.add "X-Amz-Signature", valid_774393
  var valid_774394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774394 = validateParameter(valid_774394, JString, required = false,
                                 default = nil)
  if valid_774394 != nil:
    section.add "X-Amz-SignedHeaders", valid_774394
  var valid_774395 = header.getOrDefault("X-Amz-Credential")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Credential", valid_774395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774397: Call_GetTrigger_774385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_774397.validator(path, query, header, formData, body)
  let scheme = call_774397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774397.url(scheme.get, call_774397.host, call_774397.base,
                         call_774397.route, valid.getOrDefault("path"))
  result = hook(call_774397, url, valid)

proc call*(call_774398: Call_GetTrigger_774385; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_774399 = newJObject()
  if body != nil:
    body_774399 = body
  result = call_774398.call(nil, nil, nil, nil, body_774399)

var getTrigger* = Call_GetTrigger_774385(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_774386,
                                      base: "/", url: url_GetTrigger_774387,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_774400 = ref object of OpenApiRestCall_772597
proc url_GetTriggers_774402(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTriggers_774401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774403 = query.getOrDefault("NextToken")
  valid_774403 = validateParameter(valid_774403, JString, required = false,
                                 default = nil)
  if valid_774403 != nil:
    section.add "NextToken", valid_774403
  var valid_774404 = query.getOrDefault("MaxResults")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "MaxResults", valid_774404
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
  var valid_774405 = header.getOrDefault("X-Amz-Date")
  valid_774405 = validateParameter(valid_774405, JString, required = false,
                                 default = nil)
  if valid_774405 != nil:
    section.add "X-Amz-Date", valid_774405
  var valid_774406 = header.getOrDefault("X-Amz-Security-Token")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "X-Amz-Security-Token", valid_774406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774407 = header.getOrDefault("X-Amz-Target")
  valid_774407 = validateParameter(valid_774407, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_774407 != nil:
    section.add "X-Amz-Target", valid_774407
  var valid_774408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "X-Amz-Content-Sha256", valid_774408
  var valid_774409 = header.getOrDefault("X-Amz-Algorithm")
  valid_774409 = validateParameter(valid_774409, JString, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "X-Amz-Algorithm", valid_774409
  var valid_774410 = header.getOrDefault("X-Amz-Signature")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Signature", valid_774410
  var valid_774411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "X-Amz-SignedHeaders", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Credential")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Credential", valid_774412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774414: Call_GetTriggers_774400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_774414.validator(path, query, header, formData, body)
  let scheme = call_774414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774414.url(scheme.get, call_774414.host, call_774414.base,
                         call_774414.route, valid.getOrDefault("path"))
  result = hook(call_774414, url, valid)

proc call*(call_774415: Call_GetTriggers_774400; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774416 = newJObject()
  var body_774417 = newJObject()
  add(query_774416, "NextToken", newJString(NextToken))
  if body != nil:
    body_774417 = body
  add(query_774416, "MaxResults", newJString(MaxResults))
  result = call_774415.call(nil, query_774416, nil, nil, body_774417)

var getTriggers* = Call_GetTriggers_774400(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_774401,
                                        base: "/", url: url_GetTriggers_774402,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_774418 = ref object of OpenApiRestCall_772597
proc url_GetUserDefinedFunction_774420(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUserDefinedFunction_774419(path: JsonNode; query: JsonNode;
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
  var valid_774421 = header.getOrDefault("X-Amz-Date")
  valid_774421 = validateParameter(valid_774421, JString, required = false,
                                 default = nil)
  if valid_774421 != nil:
    section.add "X-Amz-Date", valid_774421
  var valid_774422 = header.getOrDefault("X-Amz-Security-Token")
  valid_774422 = validateParameter(valid_774422, JString, required = false,
                                 default = nil)
  if valid_774422 != nil:
    section.add "X-Amz-Security-Token", valid_774422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774423 = header.getOrDefault("X-Amz-Target")
  valid_774423 = validateParameter(valid_774423, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_774423 != nil:
    section.add "X-Amz-Target", valid_774423
  var valid_774424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774424 = validateParameter(valid_774424, JString, required = false,
                                 default = nil)
  if valid_774424 != nil:
    section.add "X-Amz-Content-Sha256", valid_774424
  var valid_774425 = header.getOrDefault("X-Amz-Algorithm")
  valid_774425 = validateParameter(valid_774425, JString, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "X-Amz-Algorithm", valid_774425
  var valid_774426 = header.getOrDefault("X-Amz-Signature")
  valid_774426 = validateParameter(valid_774426, JString, required = false,
                                 default = nil)
  if valid_774426 != nil:
    section.add "X-Amz-Signature", valid_774426
  var valid_774427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774427 = validateParameter(valid_774427, JString, required = false,
                                 default = nil)
  if valid_774427 != nil:
    section.add "X-Amz-SignedHeaders", valid_774427
  var valid_774428 = header.getOrDefault("X-Amz-Credential")
  valid_774428 = validateParameter(valid_774428, JString, required = false,
                                 default = nil)
  if valid_774428 != nil:
    section.add "X-Amz-Credential", valid_774428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774430: Call_GetUserDefinedFunction_774418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_774430.validator(path, query, header, formData, body)
  let scheme = call_774430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774430.url(scheme.get, call_774430.host, call_774430.base,
                         call_774430.route, valid.getOrDefault("path"))
  result = hook(call_774430, url, valid)

proc call*(call_774431: Call_GetUserDefinedFunction_774418; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_774432 = newJObject()
  if body != nil:
    body_774432 = body
  result = call_774431.call(nil, nil, nil, nil, body_774432)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_774418(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_774419, base: "/",
    url: url_GetUserDefinedFunction_774420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_774433 = ref object of OpenApiRestCall_772597
proc url_GetUserDefinedFunctions_774435(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUserDefinedFunctions_774434(path: JsonNode; query: JsonNode;
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
  var valid_774436 = query.getOrDefault("NextToken")
  valid_774436 = validateParameter(valid_774436, JString, required = false,
                                 default = nil)
  if valid_774436 != nil:
    section.add "NextToken", valid_774436
  var valid_774437 = query.getOrDefault("MaxResults")
  valid_774437 = validateParameter(valid_774437, JString, required = false,
                                 default = nil)
  if valid_774437 != nil:
    section.add "MaxResults", valid_774437
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
  var valid_774438 = header.getOrDefault("X-Amz-Date")
  valid_774438 = validateParameter(valid_774438, JString, required = false,
                                 default = nil)
  if valid_774438 != nil:
    section.add "X-Amz-Date", valid_774438
  var valid_774439 = header.getOrDefault("X-Amz-Security-Token")
  valid_774439 = validateParameter(valid_774439, JString, required = false,
                                 default = nil)
  if valid_774439 != nil:
    section.add "X-Amz-Security-Token", valid_774439
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774440 = header.getOrDefault("X-Amz-Target")
  valid_774440 = validateParameter(valid_774440, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_774440 != nil:
    section.add "X-Amz-Target", valid_774440
  var valid_774441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774441 = validateParameter(valid_774441, JString, required = false,
                                 default = nil)
  if valid_774441 != nil:
    section.add "X-Amz-Content-Sha256", valid_774441
  var valid_774442 = header.getOrDefault("X-Amz-Algorithm")
  valid_774442 = validateParameter(valid_774442, JString, required = false,
                                 default = nil)
  if valid_774442 != nil:
    section.add "X-Amz-Algorithm", valid_774442
  var valid_774443 = header.getOrDefault("X-Amz-Signature")
  valid_774443 = validateParameter(valid_774443, JString, required = false,
                                 default = nil)
  if valid_774443 != nil:
    section.add "X-Amz-Signature", valid_774443
  var valid_774444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774444 = validateParameter(valid_774444, JString, required = false,
                                 default = nil)
  if valid_774444 != nil:
    section.add "X-Amz-SignedHeaders", valid_774444
  var valid_774445 = header.getOrDefault("X-Amz-Credential")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Credential", valid_774445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774447: Call_GetUserDefinedFunctions_774433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_774447.validator(path, query, header, formData, body)
  let scheme = call_774447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774447.url(scheme.get, call_774447.host, call_774447.base,
                         call_774447.route, valid.getOrDefault("path"))
  result = hook(call_774447, url, valid)

proc call*(call_774448: Call_GetUserDefinedFunctions_774433; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774449 = newJObject()
  var body_774450 = newJObject()
  add(query_774449, "NextToken", newJString(NextToken))
  if body != nil:
    body_774450 = body
  add(query_774449, "MaxResults", newJString(MaxResults))
  result = call_774448.call(nil, query_774449, nil, nil, body_774450)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_774433(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_774434, base: "/",
    url: url_GetUserDefinedFunctions_774435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_774451 = ref object of OpenApiRestCall_772597
proc url_GetWorkflow_774453(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetWorkflow_774452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774454 = header.getOrDefault("X-Amz-Date")
  valid_774454 = validateParameter(valid_774454, JString, required = false,
                                 default = nil)
  if valid_774454 != nil:
    section.add "X-Amz-Date", valid_774454
  var valid_774455 = header.getOrDefault("X-Amz-Security-Token")
  valid_774455 = validateParameter(valid_774455, JString, required = false,
                                 default = nil)
  if valid_774455 != nil:
    section.add "X-Amz-Security-Token", valid_774455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774456 = header.getOrDefault("X-Amz-Target")
  valid_774456 = validateParameter(valid_774456, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_774456 != nil:
    section.add "X-Amz-Target", valid_774456
  var valid_774457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774457 = validateParameter(valid_774457, JString, required = false,
                                 default = nil)
  if valid_774457 != nil:
    section.add "X-Amz-Content-Sha256", valid_774457
  var valid_774458 = header.getOrDefault("X-Amz-Algorithm")
  valid_774458 = validateParameter(valid_774458, JString, required = false,
                                 default = nil)
  if valid_774458 != nil:
    section.add "X-Amz-Algorithm", valid_774458
  var valid_774459 = header.getOrDefault("X-Amz-Signature")
  valid_774459 = validateParameter(valid_774459, JString, required = false,
                                 default = nil)
  if valid_774459 != nil:
    section.add "X-Amz-Signature", valid_774459
  var valid_774460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774460 = validateParameter(valid_774460, JString, required = false,
                                 default = nil)
  if valid_774460 != nil:
    section.add "X-Amz-SignedHeaders", valid_774460
  var valid_774461 = header.getOrDefault("X-Amz-Credential")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = nil)
  if valid_774461 != nil:
    section.add "X-Amz-Credential", valid_774461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774463: Call_GetWorkflow_774451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_774463.validator(path, query, header, formData, body)
  let scheme = call_774463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774463.url(scheme.get, call_774463.host, call_774463.base,
                         call_774463.route, valid.getOrDefault("path"))
  result = hook(call_774463, url, valid)

proc call*(call_774464: Call_GetWorkflow_774451; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_774465 = newJObject()
  if body != nil:
    body_774465 = body
  result = call_774464.call(nil, nil, nil, nil, body_774465)

var getWorkflow* = Call_GetWorkflow_774451(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_774452,
                                        base: "/", url: url_GetWorkflow_774453,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_774466 = ref object of OpenApiRestCall_772597
proc url_GetWorkflowRun_774468(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetWorkflowRun_774467(path: JsonNode; query: JsonNode;
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
  var valid_774469 = header.getOrDefault("X-Amz-Date")
  valid_774469 = validateParameter(valid_774469, JString, required = false,
                                 default = nil)
  if valid_774469 != nil:
    section.add "X-Amz-Date", valid_774469
  var valid_774470 = header.getOrDefault("X-Amz-Security-Token")
  valid_774470 = validateParameter(valid_774470, JString, required = false,
                                 default = nil)
  if valid_774470 != nil:
    section.add "X-Amz-Security-Token", valid_774470
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774471 = header.getOrDefault("X-Amz-Target")
  valid_774471 = validateParameter(valid_774471, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_774471 != nil:
    section.add "X-Amz-Target", valid_774471
  var valid_774472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774472 = validateParameter(valid_774472, JString, required = false,
                                 default = nil)
  if valid_774472 != nil:
    section.add "X-Amz-Content-Sha256", valid_774472
  var valid_774473 = header.getOrDefault("X-Amz-Algorithm")
  valid_774473 = validateParameter(valid_774473, JString, required = false,
                                 default = nil)
  if valid_774473 != nil:
    section.add "X-Amz-Algorithm", valid_774473
  var valid_774474 = header.getOrDefault("X-Amz-Signature")
  valid_774474 = validateParameter(valid_774474, JString, required = false,
                                 default = nil)
  if valid_774474 != nil:
    section.add "X-Amz-Signature", valid_774474
  var valid_774475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-SignedHeaders", valid_774475
  var valid_774476 = header.getOrDefault("X-Amz-Credential")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Credential", valid_774476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774478: Call_GetWorkflowRun_774466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_774478.validator(path, query, header, formData, body)
  let scheme = call_774478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774478.url(scheme.get, call_774478.host, call_774478.base,
                         call_774478.route, valid.getOrDefault("path"))
  result = hook(call_774478, url, valid)

proc call*(call_774479: Call_GetWorkflowRun_774466; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_774480 = newJObject()
  if body != nil:
    body_774480 = body
  result = call_774479.call(nil, nil, nil, nil, body_774480)

var getWorkflowRun* = Call_GetWorkflowRun_774466(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_774467, base: "/", url: url_GetWorkflowRun_774468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_774481 = ref object of OpenApiRestCall_772597
proc url_GetWorkflowRunProperties_774483(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetWorkflowRunProperties_774482(path: JsonNode; query: JsonNode;
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
  var valid_774484 = header.getOrDefault("X-Amz-Date")
  valid_774484 = validateParameter(valid_774484, JString, required = false,
                                 default = nil)
  if valid_774484 != nil:
    section.add "X-Amz-Date", valid_774484
  var valid_774485 = header.getOrDefault("X-Amz-Security-Token")
  valid_774485 = validateParameter(valid_774485, JString, required = false,
                                 default = nil)
  if valid_774485 != nil:
    section.add "X-Amz-Security-Token", valid_774485
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774486 = header.getOrDefault("X-Amz-Target")
  valid_774486 = validateParameter(valid_774486, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_774486 != nil:
    section.add "X-Amz-Target", valid_774486
  var valid_774487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774487 = validateParameter(valid_774487, JString, required = false,
                                 default = nil)
  if valid_774487 != nil:
    section.add "X-Amz-Content-Sha256", valid_774487
  var valid_774488 = header.getOrDefault("X-Amz-Algorithm")
  valid_774488 = validateParameter(valid_774488, JString, required = false,
                                 default = nil)
  if valid_774488 != nil:
    section.add "X-Amz-Algorithm", valid_774488
  var valid_774489 = header.getOrDefault("X-Amz-Signature")
  valid_774489 = validateParameter(valid_774489, JString, required = false,
                                 default = nil)
  if valid_774489 != nil:
    section.add "X-Amz-Signature", valid_774489
  var valid_774490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774490 = validateParameter(valid_774490, JString, required = false,
                                 default = nil)
  if valid_774490 != nil:
    section.add "X-Amz-SignedHeaders", valid_774490
  var valid_774491 = header.getOrDefault("X-Amz-Credential")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Credential", valid_774491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774493: Call_GetWorkflowRunProperties_774481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_774493.validator(path, query, header, formData, body)
  let scheme = call_774493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774493.url(scheme.get, call_774493.host, call_774493.base,
                         call_774493.route, valid.getOrDefault("path"))
  result = hook(call_774493, url, valid)

proc call*(call_774494: Call_GetWorkflowRunProperties_774481; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_774495 = newJObject()
  if body != nil:
    body_774495 = body
  result = call_774494.call(nil, nil, nil, nil, body_774495)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_774481(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_774482, base: "/",
    url: url_GetWorkflowRunProperties_774483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_774496 = ref object of OpenApiRestCall_772597
proc url_GetWorkflowRuns_774498(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetWorkflowRuns_774497(path: JsonNode; query: JsonNode;
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
  var valid_774499 = query.getOrDefault("NextToken")
  valid_774499 = validateParameter(valid_774499, JString, required = false,
                                 default = nil)
  if valid_774499 != nil:
    section.add "NextToken", valid_774499
  var valid_774500 = query.getOrDefault("MaxResults")
  valid_774500 = validateParameter(valid_774500, JString, required = false,
                                 default = nil)
  if valid_774500 != nil:
    section.add "MaxResults", valid_774500
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
  var valid_774501 = header.getOrDefault("X-Amz-Date")
  valid_774501 = validateParameter(valid_774501, JString, required = false,
                                 default = nil)
  if valid_774501 != nil:
    section.add "X-Amz-Date", valid_774501
  var valid_774502 = header.getOrDefault("X-Amz-Security-Token")
  valid_774502 = validateParameter(valid_774502, JString, required = false,
                                 default = nil)
  if valid_774502 != nil:
    section.add "X-Amz-Security-Token", valid_774502
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774503 = header.getOrDefault("X-Amz-Target")
  valid_774503 = validateParameter(valid_774503, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_774503 != nil:
    section.add "X-Amz-Target", valid_774503
  var valid_774504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774504 = validateParameter(valid_774504, JString, required = false,
                                 default = nil)
  if valid_774504 != nil:
    section.add "X-Amz-Content-Sha256", valid_774504
  var valid_774505 = header.getOrDefault("X-Amz-Algorithm")
  valid_774505 = validateParameter(valid_774505, JString, required = false,
                                 default = nil)
  if valid_774505 != nil:
    section.add "X-Amz-Algorithm", valid_774505
  var valid_774506 = header.getOrDefault("X-Amz-Signature")
  valid_774506 = validateParameter(valid_774506, JString, required = false,
                                 default = nil)
  if valid_774506 != nil:
    section.add "X-Amz-Signature", valid_774506
  var valid_774507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774507 = validateParameter(valid_774507, JString, required = false,
                                 default = nil)
  if valid_774507 != nil:
    section.add "X-Amz-SignedHeaders", valid_774507
  var valid_774508 = header.getOrDefault("X-Amz-Credential")
  valid_774508 = validateParameter(valid_774508, JString, required = false,
                                 default = nil)
  if valid_774508 != nil:
    section.add "X-Amz-Credential", valid_774508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774510: Call_GetWorkflowRuns_774496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_774510.validator(path, query, header, formData, body)
  let scheme = call_774510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774510.url(scheme.get, call_774510.host, call_774510.base,
                         call_774510.route, valid.getOrDefault("path"))
  result = hook(call_774510, url, valid)

proc call*(call_774511: Call_GetWorkflowRuns_774496; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774512 = newJObject()
  var body_774513 = newJObject()
  add(query_774512, "NextToken", newJString(NextToken))
  if body != nil:
    body_774513 = body
  add(query_774512, "MaxResults", newJString(MaxResults))
  result = call_774511.call(nil, query_774512, nil, nil, body_774513)

var getWorkflowRuns* = Call_GetWorkflowRuns_774496(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_774497, base: "/", url: url_GetWorkflowRuns_774498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_774514 = ref object of OpenApiRestCall_772597
proc url_ImportCatalogToGlue_774516(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportCatalogToGlue_774515(path: JsonNode; query: JsonNode;
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
  var valid_774517 = header.getOrDefault("X-Amz-Date")
  valid_774517 = validateParameter(valid_774517, JString, required = false,
                                 default = nil)
  if valid_774517 != nil:
    section.add "X-Amz-Date", valid_774517
  var valid_774518 = header.getOrDefault("X-Amz-Security-Token")
  valid_774518 = validateParameter(valid_774518, JString, required = false,
                                 default = nil)
  if valid_774518 != nil:
    section.add "X-Amz-Security-Token", valid_774518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774519 = header.getOrDefault("X-Amz-Target")
  valid_774519 = validateParameter(valid_774519, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_774519 != nil:
    section.add "X-Amz-Target", valid_774519
  var valid_774520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774520 = validateParameter(valid_774520, JString, required = false,
                                 default = nil)
  if valid_774520 != nil:
    section.add "X-Amz-Content-Sha256", valid_774520
  var valid_774521 = header.getOrDefault("X-Amz-Algorithm")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-Algorithm", valid_774521
  var valid_774522 = header.getOrDefault("X-Amz-Signature")
  valid_774522 = validateParameter(valid_774522, JString, required = false,
                                 default = nil)
  if valid_774522 != nil:
    section.add "X-Amz-Signature", valid_774522
  var valid_774523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774523 = validateParameter(valid_774523, JString, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "X-Amz-SignedHeaders", valid_774523
  var valid_774524 = header.getOrDefault("X-Amz-Credential")
  valid_774524 = validateParameter(valid_774524, JString, required = false,
                                 default = nil)
  if valid_774524 != nil:
    section.add "X-Amz-Credential", valid_774524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774526: Call_ImportCatalogToGlue_774514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_774526.validator(path, query, header, formData, body)
  let scheme = call_774526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774526.url(scheme.get, call_774526.host, call_774526.base,
                         call_774526.route, valid.getOrDefault("path"))
  result = hook(call_774526, url, valid)

proc call*(call_774527: Call_ImportCatalogToGlue_774514; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_774528 = newJObject()
  if body != nil:
    body_774528 = body
  result = call_774527.call(nil, nil, nil, nil, body_774528)

var importCatalogToGlue* = Call_ImportCatalogToGlue_774514(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_774515, base: "/",
    url: url_ImportCatalogToGlue_774516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_774529 = ref object of OpenApiRestCall_772597
proc url_ListCrawlers_774531(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCrawlers_774530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774532 = query.getOrDefault("NextToken")
  valid_774532 = validateParameter(valid_774532, JString, required = false,
                                 default = nil)
  if valid_774532 != nil:
    section.add "NextToken", valid_774532
  var valid_774533 = query.getOrDefault("MaxResults")
  valid_774533 = validateParameter(valid_774533, JString, required = false,
                                 default = nil)
  if valid_774533 != nil:
    section.add "MaxResults", valid_774533
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
  var valid_774534 = header.getOrDefault("X-Amz-Date")
  valid_774534 = validateParameter(valid_774534, JString, required = false,
                                 default = nil)
  if valid_774534 != nil:
    section.add "X-Amz-Date", valid_774534
  var valid_774535 = header.getOrDefault("X-Amz-Security-Token")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Security-Token", valid_774535
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774536 = header.getOrDefault("X-Amz-Target")
  valid_774536 = validateParameter(valid_774536, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_774536 != nil:
    section.add "X-Amz-Target", valid_774536
  var valid_774537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774537 = validateParameter(valid_774537, JString, required = false,
                                 default = nil)
  if valid_774537 != nil:
    section.add "X-Amz-Content-Sha256", valid_774537
  var valid_774538 = header.getOrDefault("X-Amz-Algorithm")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "X-Amz-Algorithm", valid_774538
  var valid_774539 = header.getOrDefault("X-Amz-Signature")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "X-Amz-Signature", valid_774539
  var valid_774540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "X-Amz-SignedHeaders", valid_774540
  var valid_774541 = header.getOrDefault("X-Amz-Credential")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "X-Amz-Credential", valid_774541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774543: Call_ListCrawlers_774529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_774543.validator(path, query, header, formData, body)
  let scheme = call_774543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774543.url(scheme.get, call_774543.host, call_774543.base,
                         call_774543.route, valid.getOrDefault("path"))
  result = hook(call_774543, url, valid)

proc call*(call_774544: Call_ListCrawlers_774529; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774545 = newJObject()
  var body_774546 = newJObject()
  add(query_774545, "NextToken", newJString(NextToken))
  if body != nil:
    body_774546 = body
  add(query_774545, "MaxResults", newJString(MaxResults))
  result = call_774544.call(nil, query_774545, nil, nil, body_774546)

var listCrawlers* = Call_ListCrawlers_774529(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_774530, base: "/", url: url_ListCrawlers_774531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_774547 = ref object of OpenApiRestCall_772597
proc url_ListDevEndpoints_774549(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevEndpoints_774548(path: JsonNode; query: JsonNode;
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
  var valid_774550 = query.getOrDefault("NextToken")
  valid_774550 = validateParameter(valid_774550, JString, required = false,
                                 default = nil)
  if valid_774550 != nil:
    section.add "NextToken", valid_774550
  var valid_774551 = query.getOrDefault("MaxResults")
  valid_774551 = validateParameter(valid_774551, JString, required = false,
                                 default = nil)
  if valid_774551 != nil:
    section.add "MaxResults", valid_774551
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
  var valid_774552 = header.getOrDefault("X-Amz-Date")
  valid_774552 = validateParameter(valid_774552, JString, required = false,
                                 default = nil)
  if valid_774552 != nil:
    section.add "X-Amz-Date", valid_774552
  var valid_774553 = header.getOrDefault("X-Amz-Security-Token")
  valid_774553 = validateParameter(valid_774553, JString, required = false,
                                 default = nil)
  if valid_774553 != nil:
    section.add "X-Amz-Security-Token", valid_774553
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774554 = header.getOrDefault("X-Amz-Target")
  valid_774554 = validateParameter(valid_774554, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_774554 != nil:
    section.add "X-Amz-Target", valid_774554
  var valid_774555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "X-Amz-Content-Sha256", valid_774555
  var valid_774556 = header.getOrDefault("X-Amz-Algorithm")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "X-Amz-Algorithm", valid_774556
  var valid_774557 = header.getOrDefault("X-Amz-Signature")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "X-Amz-Signature", valid_774557
  var valid_774558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774558 = validateParameter(valid_774558, JString, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "X-Amz-SignedHeaders", valid_774558
  var valid_774559 = header.getOrDefault("X-Amz-Credential")
  valid_774559 = validateParameter(valid_774559, JString, required = false,
                                 default = nil)
  if valid_774559 != nil:
    section.add "X-Amz-Credential", valid_774559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774561: Call_ListDevEndpoints_774547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_774561.validator(path, query, header, formData, body)
  let scheme = call_774561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774561.url(scheme.get, call_774561.host, call_774561.base,
                         call_774561.route, valid.getOrDefault("path"))
  result = hook(call_774561, url, valid)

proc call*(call_774562: Call_ListDevEndpoints_774547; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774563 = newJObject()
  var body_774564 = newJObject()
  add(query_774563, "NextToken", newJString(NextToken))
  if body != nil:
    body_774564 = body
  add(query_774563, "MaxResults", newJString(MaxResults))
  result = call_774562.call(nil, query_774563, nil, nil, body_774564)

var listDevEndpoints* = Call_ListDevEndpoints_774547(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_774548, base: "/",
    url: url_ListDevEndpoints_774549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_774565 = ref object of OpenApiRestCall_772597
proc url_ListJobs_774567(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobs_774566(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774568 = query.getOrDefault("NextToken")
  valid_774568 = validateParameter(valid_774568, JString, required = false,
                                 default = nil)
  if valid_774568 != nil:
    section.add "NextToken", valid_774568
  var valid_774569 = query.getOrDefault("MaxResults")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "MaxResults", valid_774569
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
  var valid_774570 = header.getOrDefault("X-Amz-Date")
  valid_774570 = validateParameter(valid_774570, JString, required = false,
                                 default = nil)
  if valid_774570 != nil:
    section.add "X-Amz-Date", valid_774570
  var valid_774571 = header.getOrDefault("X-Amz-Security-Token")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-Security-Token", valid_774571
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774572 = header.getOrDefault("X-Amz-Target")
  valid_774572 = validateParameter(valid_774572, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_774572 != nil:
    section.add "X-Amz-Target", valid_774572
  var valid_774573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774573 = validateParameter(valid_774573, JString, required = false,
                                 default = nil)
  if valid_774573 != nil:
    section.add "X-Amz-Content-Sha256", valid_774573
  var valid_774574 = header.getOrDefault("X-Amz-Algorithm")
  valid_774574 = validateParameter(valid_774574, JString, required = false,
                                 default = nil)
  if valid_774574 != nil:
    section.add "X-Amz-Algorithm", valid_774574
  var valid_774575 = header.getOrDefault("X-Amz-Signature")
  valid_774575 = validateParameter(valid_774575, JString, required = false,
                                 default = nil)
  if valid_774575 != nil:
    section.add "X-Amz-Signature", valid_774575
  var valid_774576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774576 = validateParameter(valid_774576, JString, required = false,
                                 default = nil)
  if valid_774576 != nil:
    section.add "X-Amz-SignedHeaders", valid_774576
  var valid_774577 = header.getOrDefault("X-Amz-Credential")
  valid_774577 = validateParameter(valid_774577, JString, required = false,
                                 default = nil)
  if valid_774577 != nil:
    section.add "X-Amz-Credential", valid_774577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774579: Call_ListJobs_774565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_774579.validator(path, query, header, formData, body)
  let scheme = call_774579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774579.url(scheme.get, call_774579.host, call_774579.base,
                         call_774579.route, valid.getOrDefault("path"))
  result = hook(call_774579, url, valid)

proc call*(call_774580: Call_ListJobs_774565; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774581 = newJObject()
  var body_774582 = newJObject()
  add(query_774581, "NextToken", newJString(NextToken))
  if body != nil:
    body_774582 = body
  add(query_774581, "MaxResults", newJString(MaxResults))
  result = call_774580.call(nil, query_774581, nil, nil, body_774582)

var listJobs* = Call_ListJobs_774565(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_774566, base: "/",
                                  url: url_ListJobs_774567,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_774583 = ref object of OpenApiRestCall_772597
proc url_ListTriggers_774585(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTriggers_774584(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774586 = query.getOrDefault("NextToken")
  valid_774586 = validateParameter(valid_774586, JString, required = false,
                                 default = nil)
  if valid_774586 != nil:
    section.add "NextToken", valid_774586
  var valid_774587 = query.getOrDefault("MaxResults")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "MaxResults", valid_774587
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
  var valid_774588 = header.getOrDefault("X-Amz-Date")
  valid_774588 = validateParameter(valid_774588, JString, required = false,
                                 default = nil)
  if valid_774588 != nil:
    section.add "X-Amz-Date", valid_774588
  var valid_774589 = header.getOrDefault("X-Amz-Security-Token")
  valid_774589 = validateParameter(valid_774589, JString, required = false,
                                 default = nil)
  if valid_774589 != nil:
    section.add "X-Amz-Security-Token", valid_774589
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774590 = header.getOrDefault("X-Amz-Target")
  valid_774590 = validateParameter(valid_774590, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_774590 != nil:
    section.add "X-Amz-Target", valid_774590
  var valid_774591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774591 = validateParameter(valid_774591, JString, required = false,
                                 default = nil)
  if valid_774591 != nil:
    section.add "X-Amz-Content-Sha256", valid_774591
  var valid_774592 = header.getOrDefault("X-Amz-Algorithm")
  valid_774592 = validateParameter(valid_774592, JString, required = false,
                                 default = nil)
  if valid_774592 != nil:
    section.add "X-Amz-Algorithm", valid_774592
  var valid_774593 = header.getOrDefault("X-Amz-Signature")
  valid_774593 = validateParameter(valid_774593, JString, required = false,
                                 default = nil)
  if valid_774593 != nil:
    section.add "X-Amz-Signature", valid_774593
  var valid_774594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774594 = validateParameter(valid_774594, JString, required = false,
                                 default = nil)
  if valid_774594 != nil:
    section.add "X-Amz-SignedHeaders", valid_774594
  var valid_774595 = header.getOrDefault("X-Amz-Credential")
  valid_774595 = validateParameter(valid_774595, JString, required = false,
                                 default = nil)
  if valid_774595 != nil:
    section.add "X-Amz-Credential", valid_774595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774597: Call_ListTriggers_774583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_774597.validator(path, query, header, formData, body)
  let scheme = call_774597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774597.url(scheme.get, call_774597.host, call_774597.base,
                         call_774597.route, valid.getOrDefault("path"))
  result = hook(call_774597, url, valid)

proc call*(call_774598: Call_ListTriggers_774583; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774599 = newJObject()
  var body_774600 = newJObject()
  add(query_774599, "NextToken", newJString(NextToken))
  if body != nil:
    body_774600 = body
  add(query_774599, "MaxResults", newJString(MaxResults))
  result = call_774598.call(nil, query_774599, nil, nil, body_774600)

var listTriggers* = Call_ListTriggers_774583(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_774584, base: "/", url: url_ListTriggers_774585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_774601 = ref object of OpenApiRestCall_772597
proc url_ListWorkflows_774603(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWorkflows_774602(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774604 = query.getOrDefault("NextToken")
  valid_774604 = validateParameter(valid_774604, JString, required = false,
                                 default = nil)
  if valid_774604 != nil:
    section.add "NextToken", valid_774604
  var valid_774605 = query.getOrDefault("MaxResults")
  valid_774605 = validateParameter(valid_774605, JString, required = false,
                                 default = nil)
  if valid_774605 != nil:
    section.add "MaxResults", valid_774605
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
  var valid_774606 = header.getOrDefault("X-Amz-Date")
  valid_774606 = validateParameter(valid_774606, JString, required = false,
                                 default = nil)
  if valid_774606 != nil:
    section.add "X-Amz-Date", valid_774606
  var valid_774607 = header.getOrDefault("X-Amz-Security-Token")
  valid_774607 = validateParameter(valid_774607, JString, required = false,
                                 default = nil)
  if valid_774607 != nil:
    section.add "X-Amz-Security-Token", valid_774607
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774608 = header.getOrDefault("X-Amz-Target")
  valid_774608 = validateParameter(valid_774608, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_774608 != nil:
    section.add "X-Amz-Target", valid_774608
  var valid_774609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774609 = validateParameter(valid_774609, JString, required = false,
                                 default = nil)
  if valid_774609 != nil:
    section.add "X-Amz-Content-Sha256", valid_774609
  var valid_774610 = header.getOrDefault("X-Amz-Algorithm")
  valid_774610 = validateParameter(valid_774610, JString, required = false,
                                 default = nil)
  if valid_774610 != nil:
    section.add "X-Amz-Algorithm", valid_774610
  var valid_774611 = header.getOrDefault("X-Amz-Signature")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "X-Amz-Signature", valid_774611
  var valid_774612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774612 = validateParameter(valid_774612, JString, required = false,
                                 default = nil)
  if valid_774612 != nil:
    section.add "X-Amz-SignedHeaders", valid_774612
  var valid_774613 = header.getOrDefault("X-Amz-Credential")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-Credential", valid_774613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774615: Call_ListWorkflows_774601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_774615.validator(path, query, header, formData, body)
  let scheme = call_774615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774615.url(scheme.get, call_774615.host, call_774615.base,
                         call_774615.route, valid.getOrDefault("path"))
  result = hook(call_774615, url, valid)

proc call*(call_774616: Call_ListWorkflows_774601; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774617 = newJObject()
  var body_774618 = newJObject()
  add(query_774617, "NextToken", newJString(NextToken))
  if body != nil:
    body_774618 = body
  add(query_774617, "MaxResults", newJString(MaxResults))
  result = call_774616.call(nil, query_774617, nil, nil, body_774618)

var listWorkflows* = Call_ListWorkflows_774601(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_774602, base: "/", url: url_ListWorkflows_774603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_774619 = ref object of OpenApiRestCall_772597
proc url_PutDataCatalogEncryptionSettings_774621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutDataCatalogEncryptionSettings_774620(path: JsonNode;
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
  var valid_774622 = header.getOrDefault("X-Amz-Date")
  valid_774622 = validateParameter(valid_774622, JString, required = false,
                                 default = nil)
  if valid_774622 != nil:
    section.add "X-Amz-Date", valid_774622
  var valid_774623 = header.getOrDefault("X-Amz-Security-Token")
  valid_774623 = validateParameter(valid_774623, JString, required = false,
                                 default = nil)
  if valid_774623 != nil:
    section.add "X-Amz-Security-Token", valid_774623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774624 = header.getOrDefault("X-Amz-Target")
  valid_774624 = validateParameter(valid_774624, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_774624 != nil:
    section.add "X-Amz-Target", valid_774624
  var valid_774625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774625 = validateParameter(valid_774625, JString, required = false,
                                 default = nil)
  if valid_774625 != nil:
    section.add "X-Amz-Content-Sha256", valid_774625
  var valid_774626 = header.getOrDefault("X-Amz-Algorithm")
  valid_774626 = validateParameter(valid_774626, JString, required = false,
                                 default = nil)
  if valid_774626 != nil:
    section.add "X-Amz-Algorithm", valid_774626
  var valid_774627 = header.getOrDefault("X-Amz-Signature")
  valid_774627 = validateParameter(valid_774627, JString, required = false,
                                 default = nil)
  if valid_774627 != nil:
    section.add "X-Amz-Signature", valid_774627
  var valid_774628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-SignedHeaders", valid_774628
  var valid_774629 = header.getOrDefault("X-Amz-Credential")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "X-Amz-Credential", valid_774629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774631: Call_PutDataCatalogEncryptionSettings_774619;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_774631.validator(path, query, header, formData, body)
  let scheme = call_774631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774631.url(scheme.get, call_774631.host, call_774631.base,
                         call_774631.route, valid.getOrDefault("path"))
  result = hook(call_774631, url, valid)

proc call*(call_774632: Call_PutDataCatalogEncryptionSettings_774619;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_774633 = newJObject()
  if body != nil:
    body_774633 = body
  result = call_774632.call(nil, nil, nil, nil, body_774633)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_774619(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_774620, base: "/",
    url: url_PutDataCatalogEncryptionSettings_774621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_774634 = ref object of OpenApiRestCall_772597
proc url_PutResourcePolicy_774636(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutResourcePolicy_774635(path: JsonNode; query: JsonNode;
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
  var valid_774637 = header.getOrDefault("X-Amz-Date")
  valid_774637 = validateParameter(valid_774637, JString, required = false,
                                 default = nil)
  if valid_774637 != nil:
    section.add "X-Amz-Date", valid_774637
  var valid_774638 = header.getOrDefault("X-Amz-Security-Token")
  valid_774638 = validateParameter(valid_774638, JString, required = false,
                                 default = nil)
  if valid_774638 != nil:
    section.add "X-Amz-Security-Token", valid_774638
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774639 = header.getOrDefault("X-Amz-Target")
  valid_774639 = validateParameter(valid_774639, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_774639 != nil:
    section.add "X-Amz-Target", valid_774639
  var valid_774640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774640 = validateParameter(valid_774640, JString, required = false,
                                 default = nil)
  if valid_774640 != nil:
    section.add "X-Amz-Content-Sha256", valid_774640
  var valid_774641 = header.getOrDefault("X-Amz-Algorithm")
  valid_774641 = validateParameter(valid_774641, JString, required = false,
                                 default = nil)
  if valid_774641 != nil:
    section.add "X-Amz-Algorithm", valid_774641
  var valid_774642 = header.getOrDefault("X-Amz-Signature")
  valid_774642 = validateParameter(valid_774642, JString, required = false,
                                 default = nil)
  if valid_774642 != nil:
    section.add "X-Amz-Signature", valid_774642
  var valid_774643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "X-Amz-SignedHeaders", valid_774643
  var valid_774644 = header.getOrDefault("X-Amz-Credential")
  valid_774644 = validateParameter(valid_774644, JString, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "X-Amz-Credential", valid_774644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774646: Call_PutResourcePolicy_774634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_774646.validator(path, query, header, formData, body)
  let scheme = call_774646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774646.url(scheme.get, call_774646.host, call_774646.base,
                         call_774646.route, valid.getOrDefault("path"))
  result = hook(call_774646, url, valid)

proc call*(call_774647: Call_PutResourcePolicy_774634; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_774648 = newJObject()
  if body != nil:
    body_774648 = body
  result = call_774647.call(nil, nil, nil, nil, body_774648)

var putResourcePolicy* = Call_PutResourcePolicy_774634(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_774635, base: "/",
    url: url_PutResourcePolicy_774636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_774649 = ref object of OpenApiRestCall_772597
proc url_PutWorkflowRunProperties_774651(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutWorkflowRunProperties_774650(path: JsonNode; query: JsonNode;
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
  var valid_774652 = header.getOrDefault("X-Amz-Date")
  valid_774652 = validateParameter(valid_774652, JString, required = false,
                                 default = nil)
  if valid_774652 != nil:
    section.add "X-Amz-Date", valid_774652
  var valid_774653 = header.getOrDefault("X-Amz-Security-Token")
  valid_774653 = validateParameter(valid_774653, JString, required = false,
                                 default = nil)
  if valid_774653 != nil:
    section.add "X-Amz-Security-Token", valid_774653
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774654 = header.getOrDefault("X-Amz-Target")
  valid_774654 = validateParameter(valid_774654, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_774654 != nil:
    section.add "X-Amz-Target", valid_774654
  var valid_774655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774655 = validateParameter(valid_774655, JString, required = false,
                                 default = nil)
  if valid_774655 != nil:
    section.add "X-Amz-Content-Sha256", valid_774655
  var valid_774656 = header.getOrDefault("X-Amz-Algorithm")
  valid_774656 = validateParameter(valid_774656, JString, required = false,
                                 default = nil)
  if valid_774656 != nil:
    section.add "X-Amz-Algorithm", valid_774656
  var valid_774657 = header.getOrDefault("X-Amz-Signature")
  valid_774657 = validateParameter(valid_774657, JString, required = false,
                                 default = nil)
  if valid_774657 != nil:
    section.add "X-Amz-Signature", valid_774657
  var valid_774658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774658 = validateParameter(valid_774658, JString, required = false,
                                 default = nil)
  if valid_774658 != nil:
    section.add "X-Amz-SignedHeaders", valid_774658
  var valid_774659 = header.getOrDefault("X-Amz-Credential")
  valid_774659 = validateParameter(valid_774659, JString, required = false,
                                 default = nil)
  if valid_774659 != nil:
    section.add "X-Amz-Credential", valid_774659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774661: Call_PutWorkflowRunProperties_774649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_774661.validator(path, query, header, formData, body)
  let scheme = call_774661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774661.url(scheme.get, call_774661.host, call_774661.base,
                         call_774661.route, valid.getOrDefault("path"))
  result = hook(call_774661, url, valid)

proc call*(call_774662: Call_PutWorkflowRunProperties_774649; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_774663 = newJObject()
  if body != nil:
    body_774663 = body
  result = call_774662.call(nil, nil, nil, nil, body_774663)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_774649(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_774650, base: "/",
    url: url_PutWorkflowRunProperties_774651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_774664 = ref object of OpenApiRestCall_772597
proc url_ResetJobBookmark_774666(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResetJobBookmark_774665(path: JsonNode; query: JsonNode;
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
  var valid_774667 = header.getOrDefault("X-Amz-Date")
  valid_774667 = validateParameter(valid_774667, JString, required = false,
                                 default = nil)
  if valid_774667 != nil:
    section.add "X-Amz-Date", valid_774667
  var valid_774668 = header.getOrDefault("X-Amz-Security-Token")
  valid_774668 = validateParameter(valid_774668, JString, required = false,
                                 default = nil)
  if valid_774668 != nil:
    section.add "X-Amz-Security-Token", valid_774668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774669 = header.getOrDefault("X-Amz-Target")
  valid_774669 = validateParameter(valid_774669, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_774669 != nil:
    section.add "X-Amz-Target", valid_774669
  var valid_774670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774670 = validateParameter(valid_774670, JString, required = false,
                                 default = nil)
  if valid_774670 != nil:
    section.add "X-Amz-Content-Sha256", valid_774670
  var valid_774671 = header.getOrDefault("X-Amz-Algorithm")
  valid_774671 = validateParameter(valid_774671, JString, required = false,
                                 default = nil)
  if valid_774671 != nil:
    section.add "X-Amz-Algorithm", valid_774671
  var valid_774672 = header.getOrDefault("X-Amz-Signature")
  valid_774672 = validateParameter(valid_774672, JString, required = false,
                                 default = nil)
  if valid_774672 != nil:
    section.add "X-Amz-Signature", valid_774672
  var valid_774673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774673 = validateParameter(valid_774673, JString, required = false,
                                 default = nil)
  if valid_774673 != nil:
    section.add "X-Amz-SignedHeaders", valid_774673
  var valid_774674 = header.getOrDefault("X-Amz-Credential")
  valid_774674 = validateParameter(valid_774674, JString, required = false,
                                 default = nil)
  if valid_774674 != nil:
    section.add "X-Amz-Credential", valid_774674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774676: Call_ResetJobBookmark_774664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_774676.validator(path, query, header, formData, body)
  let scheme = call_774676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774676.url(scheme.get, call_774676.host, call_774676.base,
                         call_774676.route, valid.getOrDefault("path"))
  result = hook(call_774676, url, valid)

proc call*(call_774677: Call_ResetJobBookmark_774664; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_774678 = newJObject()
  if body != nil:
    body_774678 = body
  result = call_774677.call(nil, nil, nil, nil, body_774678)

var resetJobBookmark* = Call_ResetJobBookmark_774664(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_774665, base: "/",
    url: url_ResetJobBookmark_774666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_774679 = ref object of OpenApiRestCall_772597
proc url_SearchTables_774681(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SearchTables_774680(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774682 = query.getOrDefault("NextToken")
  valid_774682 = validateParameter(valid_774682, JString, required = false,
                                 default = nil)
  if valid_774682 != nil:
    section.add "NextToken", valid_774682
  var valid_774683 = query.getOrDefault("MaxResults")
  valid_774683 = validateParameter(valid_774683, JString, required = false,
                                 default = nil)
  if valid_774683 != nil:
    section.add "MaxResults", valid_774683
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
  var valid_774684 = header.getOrDefault("X-Amz-Date")
  valid_774684 = validateParameter(valid_774684, JString, required = false,
                                 default = nil)
  if valid_774684 != nil:
    section.add "X-Amz-Date", valid_774684
  var valid_774685 = header.getOrDefault("X-Amz-Security-Token")
  valid_774685 = validateParameter(valid_774685, JString, required = false,
                                 default = nil)
  if valid_774685 != nil:
    section.add "X-Amz-Security-Token", valid_774685
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774686 = header.getOrDefault("X-Amz-Target")
  valid_774686 = validateParameter(valid_774686, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_774686 != nil:
    section.add "X-Amz-Target", valid_774686
  var valid_774687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774687 = validateParameter(valid_774687, JString, required = false,
                                 default = nil)
  if valid_774687 != nil:
    section.add "X-Amz-Content-Sha256", valid_774687
  var valid_774688 = header.getOrDefault("X-Amz-Algorithm")
  valid_774688 = validateParameter(valid_774688, JString, required = false,
                                 default = nil)
  if valid_774688 != nil:
    section.add "X-Amz-Algorithm", valid_774688
  var valid_774689 = header.getOrDefault("X-Amz-Signature")
  valid_774689 = validateParameter(valid_774689, JString, required = false,
                                 default = nil)
  if valid_774689 != nil:
    section.add "X-Amz-Signature", valid_774689
  var valid_774690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774690 = validateParameter(valid_774690, JString, required = false,
                                 default = nil)
  if valid_774690 != nil:
    section.add "X-Amz-SignedHeaders", valid_774690
  var valid_774691 = header.getOrDefault("X-Amz-Credential")
  valid_774691 = validateParameter(valid_774691, JString, required = false,
                                 default = nil)
  if valid_774691 != nil:
    section.add "X-Amz-Credential", valid_774691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774693: Call_SearchTables_774679; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_774693.validator(path, query, header, formData, body)
  let scheme = call_774693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774693.url(scheme.get, call_774693.host, call_774693.base,
                         call_774693.route, valid.getOrDefault("path"))
  result = hook(call_774693, url, valid)

proc call*(call_774694: Call_SearchTables_774679; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774695 = newJObject()
  var body_774696 = newJObject()
  add(query_774695, "NextToken", newJString(NextToken))
  if body != nil:
    body_774696 = body
  add(query_774695, "MaxResults", newJString(MaxResults))
  result = call_774694.call(nil, query_774695, nil, nil, body_774696)

var searchTables* = Call_SearchTables_774679(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_774680, base: "/", url: url_SearchTables_774681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_774697 = ref object of OpenApiRestCall_772597
proc url_StartCrawler_774699(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartCrawler_774698(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774700 = header.getOrDefault("X-Amz-Date")
  valid_774700 = validateParameter(valid_774700, JString, required = false,
                                 default = nil)
  if valid_774700 != nil:
    section.add "X-Amz-Date", valid_774700
  var valid_774701 = header.getOrDefault("X-Amz-Security-Token")
  valid_774701 = validateParameter(valid_774701, JString, required = false,
                                 default = nil)
  if valid_774701 != nil:
    section.add "X-Amz-Security-Token", valid_774701
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774702 = header.getOrDefault("X-Amz-Target")
  valid_774702 = validateParameter(valid_774702, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_774702 != nil:
    section.add "X-Amz-Target", valid_774702
  var valid_774703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "X-Amz-Content-Sha256", valid_774703
  var valid_774704 = header.getOrDefault("X-Amz-Algorithm")
  valid_774704 = validateParameter(valid_774704, JString, required = false,
                                 default = nil)
  if valid_774704 != nil:
    section.add "X-Amz-Algorithm", valid_774704
  var valid_774705 = header.getOrDefault("X-Amz-Signature")
  valid_774705 = validateParameter(valid_774705, JString, required = false,
                                 default = nil)
  if valid_774705 != nil:
    section.add "X-Amz-Signature", valid_774705
  var valid_774706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774706 = validateParameter(valid_774706, JString, required = false,
                                 default = nil)
  if valid_774706 != nil:
    section.add "X-Amz-SignedHeaders", valid_774706
  var valid_774707 = header.getOrDefault("X-Amz-Credential")
  valid_774707 = validateParameter(valid_774707, JString, required = false,
                                 default = nil)
  if valid_774707 != nil:
    section.add "X-Amz-Credential", valid_774707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774709: Call_StartCrawler_774697; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_774709.validator(path, query, header, formData, body)
  let scheme = call_774709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774709.url(scheme.get, call_774709.host, call_774709.base,
                         call_774709.route, valid.getOrDefault("path"))
  result = hook(call_774709, url, valid)

proc call*(call_774710: Call_StartCrawler_774697; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_774711 = newJObject()
  if body != nil:
    body_774711 = body
  result = call_774710.call(nil, nil, nil, nil, body_774711)

var startCrawler* = Call_StartCrawler_774697(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_774698, base: "/", url: url_StartCrawler_774699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_774712 = ref object of OpenApiRestCall_772597
proc url_StartCrawlerSchedule_774714(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartCrawlerSchedule_774713(path: JsonNode; query: JsonNode;
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
  var valid_774715 = header.getOrDefault("X-Amz-Date")
  valid_774715 = validateParameter(valid_774715, JString, required = false,
                                 default = nil)
  if valid_774715 != nil:
    section.add "X-Amz-Date", valid_774715
  var valid_774716 = header.getOrDefault("X-Amz-Security-Token")
  valid_774716 = validateParameter(valid_774716, JString, required = false,
                                 default = nil)
  if valid_774716 != nil:
    section.add "X-Amz-Security-Token", valid_774716
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774717 = header.getOrDefault("X-Amz-Target")
  valid_774717 = validateParameter(valid_774717, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_774717 != nil:
    section.add "X-Amz-Target", valid_774717
  var valid_774718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774718 = validateParameter(valid_774718, JString, required = false,
                                 default = nil)
  if valid_774718 != nil:
    section.add "X-Amz-Content-Sha256", valid_774718
  var valid_774719 = header.getOrDefault("X-Amz-Algorithm")
  valid_774719 = validateParameter(valid_774719, JString, required = false,
                                 default = nil)
  if valid_774719 != nil:
    section.add "X-Amz-Algorithm", valid_774719
  var valid_774720 = header.getOrDefault("X-Amz-Signature")
  valid_774720 = validateParameter(valid_774720, JString, required = false,
                                 default = nil)
  if valid_774720 != nil:
    section.add "X-Amz-Signature", valid_774720
  var valid_774721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774721 = validateParameter(valid_774721, JString, required = false,
                                 default = nil)
  if valid_774721 != nil:
    section.add "X-Amz-SignedHeaders", valid_774721
  var valid_774722 = header.getOrDefault("X-Amz-Credential")
  valid_774722 = validateParameter(valid_774722, JString, required = false,
                                 default = nil)
  if valid_774722 != nil:
    section.add "X-Amz-Credential", valid_774722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774724: Call_StartCrawlerSchedule_774712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_774724.validator(path, query, header, formData, body)
  let scheme = call_774724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774724.url(scheme.get, call_774724.host, call_774724.base,
                         call_774724.route, valid.getOrDefault("path"))
  result = hook(call_774724, url, valid)

proc call*(call_774725: Call_StartCrawlerSchedule_774712; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_774726 = newJObject()
  if body != nil:
    body_774726 = body
  result = call_774725.call(nil, nil, nil, nil, body_774726)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_774712(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_774713, base: "/",
    url: url_StartCrawlerSchedule_774714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_774727 = ref object of OpenApiRestCall_772597
proc url_StartExportLabelsTaskRun_774729(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartExportLabelsTaskRun_774728(path: JsonNode; query: JsonNode;
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
  var valid_774730 = header.getOrDefault("X-Amz-Date")
  valid_774730 = validateParameter(valid_774730, JString, required = false,
                                 default = nil)
  if valid_774730 != nil:
    section.add "X-Amz-Date", valid_774730
  var valid_774731 = header.getOrDefault("X-Amz-Security-Token")
  valid_774731 = validateParameter(valid_774731, JString, required = false,
                                 default = nil)
  if valid_774731 != nil:
    section.add "X-Amz-Security-Token", valid_774731
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774732 = header.getOrDefault("X-Amz-Target")
  valid_774732 = validateParameter(valid_774732, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_774732 != nil:
    section.add "X-Amz-Target", valid_774732
  var valid_774733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774733 = validateParameter(valid_774733, JString, required = false,
                                 default = nil)
  if valid_774733 != nil:
    section.add "X-Amz-Content-Sha256", valid_774733
  var valid_774734 = header.getOrDefault("X-Amz-Algorithm")
  valid_774734 = validateParameter(valid_774734, JString, required = false,
                                 default = nil)
  if valid_774734 != nil:
    section.add "X-Amz-Algorithm", valid_774734
  var valid_774735 = header.getOrDefault("X-Amz-Signature")
  valid_774735 = validateParameter(valid_774735, JString, required = false,
                                 default = nil)
  if valid_774735 != nil:
    section.add "X-Amz-Signature", valid_774735
  var valid_774736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774736 = validateParameter(valid_774736, JString, required = false,
                                 default = nil)
  if valid_774736 != nil:
    section.add "X-Amz-SignedHeaders", valid_774736
  var valid_774737 = header.getOrDefault("X-Amz-Credential")
  valid_774737 = validateParameter(valid_774737, JString, required = false,
                                 default = nil)
  if valid_774737 != nil:
    section.add "X-Amz-Credential", valid_774737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774739: Call_StartExportLabelsTaskRun_774727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_774739.validator(path, query, header, formData, body)
  let scheme = call_774739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774739.url(scheme.get, call_774739.host, call_774739.base,
                         call_774739.route, valid.getOrDefault("path"))
  result = hook(call_774739, url, valid)

proc call*(call_774740: Call_StartExportLabelsTaskRun_774727; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_774741 = newJObject()
  if body != nil:
    body_774741 = body
  result = call_774740.call(nil, nil, nil, nil, body_774741)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_774727(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_774728, base: "/",
    url: url_StartExportLabelsTaskRun_774729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_774742 = ref object of OpenApiRestCall_772597
proc url_StartImportLabelsTaskRun_774744(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartImportLabelsTaskRun_774743(path: JsonNode; query: JsonNode;
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
  var valid_774745 = header.getOrDefault("X-Amz-Date")
  valid_774745 = validateParameter(valid_774745, JString, required = false,
                                 default = nil)
  if valid_774745 != nil:
    section.add "X-Amz-Date", valid_774745
  var valid_774746 = header.getOrDefault("X-Amz-Security-Token")
  valid_774746 = validateParameter(valid_774746, JString, required = false,
                                 default = nil)
  if valid_774746 != nil:
    section.add "X-Amz-Security-Token", valid_774746
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774747 = header.getOrDefault("X-Amz-Target")
  valid_774747 = validateParameter(valid_774747, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_774747 != nil:
    section.add "X-Amz-Target", valid_774747
  var valid_774748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774748 = validateParameter(valid_774748, JString, required = false,
                                 default = nil)
  if valid_774748 != nil:
    section.add "X-Amz-Content-Sha256", valid_774748
  var valid_774749 = header.getOrDefault("X-Amz-Algorithm")
  valid_774749 = validateParameter(valid_774749, JString, required = false,
                                 default = nil)
  if valid_774749 != nil:
    section.add "X-Amz-Algorithm", valid_774749
  var valid_774750 = header.getOrDefault("X-Amz-Signature")
  valid_774750 = validateParameter(valid_774750, JString, required = false,
                                 default = nil)
  if valid_774750 != nil:
    section.add "X-Amz-Signature", valid_774750
  var valid_774751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774751 = validateParameter(valid_774751, JString, required = false,
                                 default = nil)
  if valid_774751 != nil:
    section.add "X-Amz-SignedHeaders", valid_774751
  var valid_774752 = header.getOrDefault("X-Amz-Credential")
  valid_774752 = validateParameter(valid_774752, JString, required = false,
                                 default = nil)
  if valid_774752 != nil:
    section.add "X-Amz-Credential", valid_774752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774754: Call_StartImportLabelsTaskRun_774742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_774754.validator(path, query, header, formData, body)
  let scheme = call_774754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774754.url(scheme.get, call_774754.host, call_774754.base,
                         call_774754.route, valid.getOrDefault("path"))
  result = hook(call_774754, url, valid)

proc call*(call_774755: Call_StartImportLabelsTaskRun_774742; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_774756 = newJObject()
  if body != nil:
    body_774756 = body
  result = call_774755.call(nil, nil, nil, nil, body_774756)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_774742(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_774743, base: "/",
    url: url_StartImportLabelsTaskRun_774744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_774757 = ref object of OpenApiRestCall_772597
proc url_StartJobRun_774759(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartJobRun_774758(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774760 = header.getOrDefault("X-Amz-Date")
  valid_774760 = validateParameter(valid_774760, JString, required = false,
                                 default = nil)
  if valid_774760 != nil:
    section.add "X-Amz-Date", valid_774760
  var valid_774761 = header.getOrDefault("X-Amz-Security-Token")
  valid_774761 = validateParameter(valid_774761, JString, required = false,
                                 default = nil)
  if valid_774761 != nil:
    section.add "X-Amz-Security-Token", valid_774761
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774762 = header.getOrDefault("X-Amz-Target")
  valid_774762 = validateParameter(valid_774762, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_774762 != nil:
    section.add "X-Amz-Target", valid_774762
  var valid_774763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774763 = validateParameter(valid_774763, JString, required = false,
                                 default = nil)
  if valid_774763 != nil:
    section.add "X-Amz-Content-Sha256", valid_774763
  var valid_774764 = header.getOrDefault("X-Amz-Algorithm")
  valid_774764 = validateParameter(valid_774764, JString, required = false,
                                 default = nil)
  if valid_774764 != nil:
    section.add "X-Amz-Algorithm", valid_774764
  var valid_774765 = header.getOrDefault("X-Amz-Signature")
  valid_774765 = validateParameter(valid_774765, JString, required = false,
                                 default = nil)
  if valid_774765 != nil:
    section.add "X-Amz-Signature", valid_774765
  var valid_774766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774766 = validateParameter(valid_774766, JString, required = false,
                                 default = nil)
  if valid_774766 != nil:
    section.add "X-Amz-SignedHeaders", valid_774766
  var valid_774767 = header.getOrDefault("X-Amz-Credential")
  valid_774767 = validateParameter(valid_774767, JString, required = false,
                                 default = nil)
  if valid_774767 != nil:
    section.add "X-Amz-Credential", valid_774767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774769: Call_StartJobRun_774757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_774769.validator(path, query, header, formData, body)
  let scheme = call_774769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774769.url(scheme.get, call_774769.host, call_774769.base,
                         call_774769.route, valid.getOrDefault("path"))
  result = hook(call_774769, url, valid)

proc call*(call_774770: Call_StartJobRun_774757; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_774771 = newJObject()
  if body != nil:
    body_774771 = body
  result = call_774770.call(nil, nil, nil, nil, body_774771)

var startJobRun* = Call_StartJobRun_774757(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_774758,
                                        base: "/", url: url_StartJobRun_774759,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_774772 = ref object of OpenApiRestCall_772597
proc url_StartMLEvaluationTaskRun_774774(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartMLEvaluationTaskRun_774773(path: JsonNode; query: JsonNode;
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
  var valid_774775 = header.getOrDefault("X-Amz-Date")
  valid_774775 = validateParameter(valid_774775, JString, required = false,
                                 default = nil)
  if valid_774775 != nil:
    section.add "X-Amz-Date", valid_774775
  var valid_774776 = header.getOrDefault("X-Amz-Security-Token")
  valid_774776 = validateParameter(valid_774776, JString, required = false,
                                 default = nil)
  if valid_774776 != nil:
    section.add "X-Amz-Security-Token", valid_774776
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774777 = header.getOrDefault("X-Amz-Target")
  valid_774777 = validateParameter(valid_774777, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_774777 != nil:
    section.add "X-Amz-Target", valid_774777
  var valid_774778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774778 = validateParameter(valid_774778, JString, required = false,
                                 default = nil)
  if valid_774778 != nil:
    section.add "X-Amz-Content-Sha256", valid_774778
  var valid_774779 = header.getOrDefault("X-Amz-Algorithm")
  valid_774779 = validateParameter(valid_774779, JString, required = false,
                                 default = nil)
  if valid_774779 != nil:
    section.add "X-Amz-Algorithm", valid_774779
  var valid_774780 = header.getOrDefault("X-Amz-Signature")
  valid_774780 = validateParameter(valid_774780, JString, required = false,
                                 default = nil)
  if valid_774780 != nil:
    section.add "X-Amz-Signature", valid_774780
  var valid_774781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774781 = validateParameter(valid_774781, JString, required = false,
                                 default = nil)
  if valid_774781 != nil:
    section.add "X-Amz-SignedHeaders", valid_774781
  var valid_774782 = header.getOrDefault("X-Amz-Credential")
  valid_774782 = validateParameter(valid_774782, JString, required = false,
                                 default = nil)
  if valid_774782 != nil:
    section.add "X-Amz-Credential", valid_774782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774784: Call_StartMLEvaluationTaskRun_774772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_774784.validator(path, query, header, formData, body)
  let scheme = call_774784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774784.url(scheme.get, call_774784.host, call_774784.base,
                         call_774784.route, valid.getOrDefault("path"))
  result = hook(call_774784, url, valid)

proc call*(call_774785: Call_StartMLEvaluationTaskRun_774772; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_774786 = newJObject()
  if body != nil:
    body_774786 = body
  result = call_774785.call(nil, nil, nil, nil, body_774786)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_774772(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_774773, base: "/",
    url: url_StartMLEvaluationTaskRun_774774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_774787 = ref object of OpenApiRestCall_772597
proc url_StartMLLabelingSetGenerationTaskRun_774789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartMLLabelingSetGenerationTaskRun_774788(path: JsonNode;
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
  var valid_774790 = header.getOrDefault("X-Amz-Date")
  valid_774790 = validateParameter(valid_774790, JString, required = false,
                                 default = nil)
  if valid_774790 != nil:
    section.add "X-Amz-Date", valid_774790
  var valid_774791 = header.getOrDefault("X-Amz-Security-Token")
  valid_774791 = validateParameter(valid_774791, JString, required = false,
                                 default = nil)
  if valid_774791 != nil:
    section.add "X-Amz-Security-Token", valid_774791
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774792 = header.getOrDefault("X-Amz-Target")
  valid_774792 = validateParameter(valid_774792, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_774792 != nil:
    section.add "X-Amz-Target", valid_774792
  var valid_774793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774793 = validateParameter(valid_774793, JString, required = false,
                                 default = nil)
  if valid_774793 != nil:
    section.add "X-Amz-Content-Sha256", valid_774793
  var valid_774794 = header.getOrDefault("X-Amz-Algorithm")
  valid_774794 = validateParameter(valid_774794, JString, required = false,
                                 default = nil)
  if valid_774794 != nil:
    section.add "X-Amz-Algorithm", valid_774794
  var valid_774795 = header.getOrDefault("X-Amz-Signature")
  valid_774795 = validateParameter(valid_774795, JString, required = false,
                                 default = nil)
  if valid_774795 != nil:
    section.add "X-Amz-Signature", valid_774795
  var valid_774796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774796 = validateParameter(valid_774796, JString, required = false,
                                 default = nil)
  if valid_774796 != nil:
    section.add "X-Amz-SignedHeaders", valid_774796
  var valid_774797 = header.getOrDefault("X-Amz-Credential")
  valid_774797 = validateParameter(valid_774797, JString, required = false,
                                 default = nil)
  if valid_774797 != nil:
    section.add "X-Amz-Credential", valid_774797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774799: Call_StartMLLabelingSetGenerationTaskRun_774787;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_774799.validator(path, query, header, formData, body)
  let scheme = call_774799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774799.url(scheme.get, call_774799.host, call_774799.base,
                         call_774799.route, valid.getOrDefault("path"))
  result = hook(call_774799, url, valid)

proc call*(call_774800: Call_StartMLLabelingSetGenerationTaskRun_774787;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_774801 = newJObject()
  if body != nil:
    body_774801 = body
  result = call_774800.call(nil, nil, nil, nil, body_774801)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_774787(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_774788, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_774789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_774802 = ref object of OpenApiRestCall_772597
proc url_StartTrigger_774804(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartTrigger_774803(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774805 = header.getOrDefault("X-Amz-Date")
  valid_774805 = validateParameter(valid_774805, JString, required = false,
                                 default = nil)
  if valid_774805 != nil:
    section.add "X-Amz-Date", valid_774805
  var valid_774806 = header.getOrDefault("X-Amz-Security-Token")
  valid_774806 = validateParameter(valid_774806, JString, required = false,
                                 default = nil)
  if valid_774806 != nil:
    section.add "X-Amz-Security-Token", valid_774806
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774807 = header.getOrDefault("X-Amz-Target")
  valid_774807 = validateParameter(valid_774807, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_774807 != nil:
    section.add "X-Amz-Target", valid_774807
  var valid_774808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774808 = validateParameter(valid_774808, JString, required = false,
                                 default = nil)
  if valid_774808 != nil:
    section.add "X-Amz-Content-Sha256", valid_774808
  var valid_774809 = header.getOrDefault("X-Amz-Algorithm")
  valid_774809 = validateParameter(valid_774809, JString, required = false,
                                 default = nil)
  if valid_774809 != nil:
    section.add "X-Amz-Algorithm", valid_774809
  var valid_774810 = header.getOrDefault("X-Amz-Signature")
  valid_774810 = validateParameter(valid_774810, JString, required = false,
                                 default = nil)
  if valid_774810 != nil:
    section.add "X-Amz-Signature", valid_774810
  var valid_774811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774811 = validateParameter(valid_774811, JString, required = false,
                                 default = nil)
  if valid_774811 != nil:
    section.add "X-Amz-SignedHeaders", valid_774811
  var valid_774812 = header.getOrDefault("X-Amz-Credential")
  valid_774812 = validateParameter(valid_774812, JString, required = false,
                                 default = nil)
  if valid_774812 != nil:
    section.add "X-Amz-Credential", valid_774812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774814: Call_StartTrigger_774802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_774814.validator(path, query, header, formData, body)
  let scheme = call_774814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774814.url(scheme.get, call_774814.host, call_774814.base,
                         call_774814.route, valid.getOrDefault("path"))
  result = hook(call_774814, url, valid)

proc call*(call_774815: Call_StartTrigger_774802; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_774816 = newJObject()
  if body != nil:
    body_774816 = body
  result = call_774815.call(nil, nil, nil, nil, body_774816)

var startTrigger* = Call_StartTrigger_774802(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_774803, base: "/", url: url_StartTrigger_774804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_774817 = ref object of OpenApiRestCall_772597
proc url_StartWorkflowRun_774819(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartWorkflowRun_774818(path: JsonNode; query: JsonNode;
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
  var valid_774820 = header.getOrDefault("X-Amz-Date")
  valid_774820 = validateParameter(valid_774820, JString, required = false,
                                 default = nil)
  if valid_774820 != nil:
    section.add "X-Amz-Date", valid_774820
  var valid_774821 = header.getOrDefault("X-Amz-Security-Token")
  valid_774821 = validateParameter(valid_774821, JString, required = false,
                                 default = nil)
  if valid_774821 != nil:
    section.add "X-Amz-Security-Token", valid_774821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774822 = header.getOrDefault("X-Amz-Target")
  valid_774822 = validateParameter(valid_774822, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_774822 != nil:
    section.add "X-Amz-Target", valid_774822
  var valid_774823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774823 = validateParameter(valid_774823, JString, required = false,
                                 default = nil)
  if valid_774823 != nil:
    section.add "X-Amz-Content-Sha256", valid_774823
  var valid_774824 = header.getOrDefault("X-Amz-Algorithm")
  valid_774824 = validateParameter(valid_774824, JString, required = false,
                                 default = nil)
  if valid_774824 != nil:
    section.add "X-Amz-Algorithm", valid_774824
  var valid_774825 = header.getOrDefault("X-Amz-Signature")
  valid_774825 = validateParameter(valid_774825, JString, required = false,
                                 default = nil)
  if valid_774825 != nil:
    section.add "X-Amz-Signature", valid_774825
  var valid_774826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774826 = validateParameter(valid_774826, JString, required = false,
                                 default = nil)
  if valid_774826 != nil:
    section.add "X-Amz-SignedHeaders", valid_774826
  var valid_774827 = header.getOrDefault("X-Amz-Credential")
  valid_774827 = validateParameter(valid_774827, JString, required = false,
                                 default = nil)
  if valid_774827 != nil:
    section.add "X-Amz-Credential", valid_774827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774829: Call_StartWorkflowRun_774817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_774829.validator(path, query, header, formData, body)
  let scheme = call_774829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774829.url(scheme.get, call_774829.host, call_774829.base,
                         call_774829.route, valid.getOrDefault("path"))
  result = hook(call_774829, url, valid)

proc call*(call_774830: Call_StartWorkflowRun_774817; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_774831 = newJObject()
  if body != nil:
    body_774831 = body
  result = call_774830.call(nil, nil, nil, nil, body_774831)

var startWorkflowRun* = Call_StartWorkflowRun_774817(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_774818, base: "/",
    url: url_StartWorkflowRun_774819, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_774832 = ref object of OpenApiRestCall_772597
proc url_StopCrawler_774834(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopCrawler_774833(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774835 = header.getOrDefault("X-Amz-Date")
  valid_774835 = validateParameter(valid_774835, JString, required = false,
                                 default = nil)
  if valid_774835 != nil:
    section.add "X-Amz-Date", valid_774835
  var valid_774836 = header.getOrDefault("X-Amz-Security-Token")
  valid_774836 = validateParameter(valid_774836, JString, required = false,
                                 default = nil)
  if valid_774836 != nil:
    section.add "X-Amz-Security-Token", valid_774836
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774837 = header.getOrDefault("X-Amz-Target")
  valid_774837 = validateParameter(valid_774837, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_774837 != nil:
    section.add "X-Amz-Target", valid_774837
  var valid_774838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774838 = validateParameter(valid_774838, JString, required = false,
                                 default = nil)
  if valid_774838 != nil:
    section.add "X-Amz-Content-Sha256", valid_774838
  var valid_774839 = header.getOrDefault("X-Amz-Algorithm")
  valid_774839 = validateParameter(valid_774839, JString, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "X-Amz-Algorithm", valid_774839
  var valid_774840 = header.getOrDefault("X-Amz-Signature")
  valid_774840 = validateParameter(valid_774840, JString, required = false,
                                 default = nil)
  if valid_774840 != nil:
    section.add "X-Amz-Signature", valid_774840
  var valid_774841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774841 = validateParameter(valid_774841, JString, required = false,
                                 default = nil)
  if valid_774841 != nil:
    section.add "X-Amz-SignedHeaders", valid_774841
  var valid_774842 = header.getOrDefault("X-Amz-Credential")
  valid_774842 = validateParameter(valid_774842, JString, required = false,
                                 default = nil)
  if valid_774842 != nil:
    section.add "X-Amz-Credential", valid_774842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774844: Call_StopCrawler_774832; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_774844.validator(path, query, header, formData, body)
  let scheme = call_774844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774844.url(scheme.get, call_774844.host, call_774844.base,
                         call_774844.route, valid.getOrDefault("path"))
  result = hook(call_774844, url, valid)

proc call*(call_774845: Call_StopCrawler_774832; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_774846 = newJObject()
  if body != nil:
    body_774846 = body
  result = call_774845.call(nil, nil, nil, nil, body_774846)

var stopCrawler* = Call_StopCrawler_774832(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_774833,
                                        base: "/", url: url_StopCrawler_774834,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_774847 = ref object of OpenApiRestCall_772597
proc url_StopCrawlerSchedule_774849(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopCrawlerSchedule_774848(path: JsonNode; query: JsonNode;
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
  var valid_774850 = header.getOrDefault("X-Amz-Date")
  valid_774850 = validateParameter(valid_774850, JString, required = false,
                                 default = nil)
  if valid_774850 != nil:
    section.add "X-Amz-Date", valid_774850
  var valid_774851 = header.getOrDefault("X-Amz-Security-Token")
  valid_774851 = validateParameter(valid_774851, JString, required = false,
                                 default = nil)
  if valid_774851 != nil:
    section.add "X-Amz-Security-Token", valid_774851
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774852 = header.getOrDefault("X-Amz-Target")
  valid_774852 = validateParameter(valid_774852, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_774852 != nil:
    section.add "X-Amz-Target", valid_774852
  var valid_774853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774853 = validateParameter(valid_774853, JString, required = false,
                                 default = nil)
  if valid_774853 != nil:
    section.add "X-Amz-Content-Sha256", valid_774853
  var valid_774854 = header.getOrDefault("X-Amz-Algorithm")
  valid_774854 = validateParameter(valid_774854, JString, required = false,
                                 default = nil)
  if valid_774854 != nil:
    section.add "X-Amz-Algorithm", valid_774854
  var valid_774855 = header.getOrDefault("X-Amz-Signature")
  valid_774855 = validateParameter(valid_774855, JString, required = false,
                                 default = nil)
  if valid_774855 != nil:
    section.add "X-Amz-Signature", valid_774855
  var valid_774856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774856 = validateParameter(valid_774856, JString, required = false,
                                 default = nil)
  if valid_774856 != nil:
    section.add "X-Amz-SignedHeaders", valid_774856
  var valid_774857 = header.getOrDefault("X-Amz-Credential")
  valid_774857 = validateParameter(valid_774857, JString, required = false,
                                 default = nil)
  if valid_774857 != nil:
    section.add "X-Amz-Credential", valid_774857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774859: Call_StopCrawlerSchedule_774847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_774859.validator(path, query, header, formData, body)
  let scheme = call_774859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774859.url(scheme.get, call_774859.host, call_774859.base,
                         call_774859.route, valid.getOrDefault("path"))
  result = hook(call_774859, url, valid)

proc call*(call_774860: Call_StopCrawlerSchedule_774847; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_774861 = newJObject()
  if body != nil:
    body_774861 = body
  result = call_774860.call(nil, nil, nil, nil, body_774861)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_774847(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_774848, base: "/",
    url: url_StopCrawlerSchedule_774849, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_774862 = ref object of OpenApiRestCall_772597
proc url_StopTrigger_774864(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopTrigger_774863(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774865 = header.getOrDefault("X-Amz-Date")
  valid_774865 = validateParameter(valid_774865, JString, required = false,
                                 default = nil)
  if valid_774865 != nil:
    section.add "X-Amz-Date", valid_774865
  var valid_774866 = header.getOrDefault("X-Amz-Security-Token")
  valid_774866 = validateParameter(valid_774866, JString, required = false,
                                 default = nil)
  if valid_774866 != nil:
    section.add "X-Amz-Security-Token", valid_774866
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774867 = header.getOrDefault("X-Amz-Target")
  valid_774867 = validateParameter(valid_774867, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_774867 != nil:
    section.add "X-Amz-Target", valid_774867
  var valid_774868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774868 = validateParameter(valid_774868, JString, required = false,
                                 default = nil)
  if valid_774868 != nil:
    section.add "X-Amz-Content-Sha256", valid_774868
  var valid_774869 = header.getOrDefault("X-Amz-Algorithm")
  valid_774869 = validateParameter(valid_774869, JString, required = false,
                                 default = nil)
  if valid_774869 != nil:
    section.add "X-Amz-Algorithm", valid_774869
  var valid_774870 = header.getOrDefault("X-Amz-Signature")
  valid_774870 = validateParameter(valid_774870, JString, required = false,
                                 default = nil)
  if valid_774870 != nil:
    section.add "X-Amz-Signature", valid_774870
  var valid_774871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774871 = validateParameter(valid_774871, JString, required = false,
                                 default = nil)
  if valid_774871 != nil:
    section.add "X-Amz-SignedHeaders", valid_774871
  var valid_774872 = header.getOrDefault("X-Amz-Credential")
  valid_774872 = validateParameter(valid_774872, JString, required = false,
                                 default = nil)
  if valid_774872 != nil:
    section.add "X-Amz-Credential", valid_774872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774874: Call_StopTrigger_774862; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_774874.validator(path, query, header, formData, body)
  let scheme = call_774874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774874.url(scheme.get, call_774874.host, call_774874.base,
                         call_774874.route, valid.getOrDefault("path"))
  result = hook(call_774874, url, valid)

proc call*(call_774875: Call_StopTrigger_774862; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_774876 = newJObject()
  if body != nil:
    body_774876 = body
  result = call_774875.call(nil, nil, nil, nil, body_774876)

var stopTrigger* = Call_StopTrigger_774862(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_774863,
                                        base: "/", url: url_StopTrigger_774864,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774877 = ref object of OpenApiRestCall_772597
proc url_TagResource_774879(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_774878(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774880 = header.getOrDefault("X-Amz-Date")
  valid_774880 = validateParameter(valid_774880, JString, required = false,
                                 default = nil)
  if valid_774880 != nil:
    section.add "X-Amz-Date", valid_774880
  var valid_774881 = header.getOrDefault("X-Amz-Security-Token")
  valid_774881 = validateParameter(valid_774881, JString, required = false,
                                 default = nil)
  if valid_774881 != nil:
    section.add "X-Amz-Security-Token", valid_774881
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774882 = header.getOrDefault("X-Amz-Target")
  valid_774882 = validateParameter(valid_774882, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_774882 != nil:
    section.add "X-Amz-Target", valid_774882
  var valid_774883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774883 = validateParameter(valid_774883, JString, required = false,
                                 default = nil)
  if valid_774883 != nil:
    section.add "X-Amz-Content-Sha256", valid_774883
  var valid_774884 = header.getOrDefault("X-Amz-Algorithm")
  valid_774884 = validateParameter(valid_774884, JString, required = false,
                                 default = nil)
  if valid_774884 != nil:
    section.add "X-Amz-Algorithm", valid_774884
  var valid_774885 = header.getOrDefault("X-Amz-Signature")
  valid_774885 = validateParameter(valid_774885, JString, required = false,
                                 default = nil)
  if valid_774885 != nil:
    section.add "X-Amz-Signature", valid_774885
  var valid_774886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774886 = validateParameter(valid_774886, JString, required = false,
                                 default = nil)
  if valid_774886 != nil:
    section.add "X-Amz-SignedHeaders", valid_774886
  var valid_774887 = header.getOrDefault("X-Amz-Credential")
  valid_774887 = validateParameter(valid_774887, JString, required = false,
                                 default = nil)
  if valid_774887 != nil:
    section.add "X-Amz-Credential", valid_774887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774889: Call_TagResource_774877; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_774889.validator(path, query, header, formData, body)
  let scheme = call_774889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774889.url(scheme.get, call_774889.host, call_774889.base,
                         call_774889.route, valid.getOrDefault("path"))
  result = hook(call_774889, url, valid)

proc call*(call_774890: Call_TagResource_774877; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_774891 = newJObject()
  if body != nil:
    body_774891 = body
  result = call_774890.call(nil, nil, nil, nil, body_774891)

var tagResource* = Call_TagResource_774877(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_774878,
                                        base: "/", url: url_TagResource_774879,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774892 = ref object of OpenApiRestCall_772597
proc url_UntagResource_774894(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_774893(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774895 = header.getOrDefault("X-Amz-Date")
  valid_774895 = validateParameter(valid_774895, JString, required = false,
                                 default = nil)
  if valid_774895 != nil:
    section.add "X-Amz-Date", valid_774895
  var valid_774896 = header.getOrDefault("X-Amz-Security-Token")
  valid_774896 = validateParameter(valid_774896, JString, required = false,
                                 default = nil)
  if valid_774896 != nil:
    section.add "X-Amz-Security-Token", valid_774896
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774897 = header.getOrDefault("X-Amz-Target")
  valid_774897 = validateParameter(valid_774897, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_774897 != nil:
    section.add "X-Amz-Target", valid_774897
  var valid_774898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774898 = validateParameter(valid_774898, JString, required = false,
                                 default = nil)
  if valid_774898 != nil:
    section.add "X-Amz-Content-Sha256", valid_774898
  var valid_774899 = header.getOrDefault("X-Amz-Algorithm")
  valid_774899 = validateParameter(valid_774899, JString, required = false,
                                 default = nil)
  if valid_774899 != nil:
    section.add "X-Amz-Algorithm", valid_774899
  var valid_774900 = header.getOrDefault("X-Amz-Signature")
  valid_774900 = validateParameter(valid_774900, JString, required = false,
                                 default = nil)
  if valid_774900 != nil:
    section.add "X-Amz-Signature", valid_774900
  var valid_774901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774901 = validateParameter(valid_774901, JString, required = false,
                                 default = nil)
  if valid_774901 != nil:
    section.add "X-Amz-SignedHeaders", valid_774901
  var valid_774902 = header.getOrDefault("X-Amz-Credential")
  valid_774902 = validateParameter(valid_774902, JString, required = false,
                                 default = nil)
  if valid_774902 != nil:
    section.add "X-Amz-Credential", valid_774902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774904: Call_UntagResource_774892; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_774904.validator(path, query, header, formData, body)
  let scheme = call_774904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774904.url(scheme.get, call_774904.host, call_774904.base,
                         call_774904.route, valid.getOrDefault("path"))
  result = hook(call_774904, url, valid)

proc call*(call_774905: Call_UntagResource_774892; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_774906 = newJObject()
  if body != nil:
    body_774906 = body
  result = call_774905.call(nil, nil, nil, nil, body_774906)

var untagResource* = Call_UntagResource_774892(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_774893, base: "/", url: url_UntagResource_774894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_774907 = ref object of OpenApiRestCall_772597
proc url_UpdateClassifier_774909(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateClassifier_774908(path: JsonNode; query: JsonNode;
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
  var valid_774910 = header.getOrDefault("X-Amz-Date")
  valid_774910 = validateParameter(valid_774910, JString, required = false,
                                 default = nil)
  if valid_774910 != nil:
    section.add "X-Amz-Date", valid_774910
  var valid_774911 = header.getOrDefault("X-Amz-Security-Token")
  valid_774911 = validateParameter(valid_774911, JString, required = false,
                                 default = nil)
  if valid_774911 != nil:
    section.add "X-Amz-Security-Token", valid_774911
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774912 = header.getOrDefault("X-Amz-Target")
  valid_774912 = validateParameter(valid_774912, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_774912 != nil:
    section.add "X-Amz-Target", valid_774912
  var valid_774913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774913 = validateParameter(valid_774913, JString, required = false,
                                 default = nil)
  if valid_774913 != nil:
    section.add "X-Amz-Content-Sha256", valid_774913
  var valid_774914 = header.getOrDefault("X-Amz-Algorithm")
  valid_774914 = validateParameter(valid_774914, JString, required = false,
                                 default = nil)
  if valid_774914 != nil:
    section.add "X-Amz-Algorithm", valid_774914
  var valid_774915 = header.getOrDefault("X-Amz-Signature")
  valid_774915 = validateParameter(valid_774915, JString, required = false,
                                 default = nil)
  if valid_774915 != nil:
    section.add "X-Amz-Signature", valid_774915
  var valid_774916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774916 = validateParameter(valid_774916, JString, required = false,
                                 default = nil)
  if valid_774916 != nil:
    section.add "X-Amz-SignedHeaders", valid_774916
  var valid_774917 = header.getOrDefault("X-Amz-Credential")
  valid_774917 = validateParameter(valid_774917, JString, required = false,
                                 default = nil)
  if valid_774917 != nil:
    section.add "X-Amz-Credential", valid_774917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774919: Call_UpdateClassifier_774907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_774919.validator(path, query, header, formData, body)
  let scheme = call_774919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774919.url(scheme.get, call_774919.host, call_774919.base,
                         call_774919.route, valid.getOrDefault("path"))
  result = hook(call_774919, url, valid)

proc call*(call_774920: Call_UpdateClassifier_774907; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_774921 = newJObject()
  if body != nil:
    body_774921 = body
  result = call_774920.call(nil, nil, nil, nil, body_774921)

var updateClassifier* = Call_UpdateClassifier_774907(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_774908, base: "/",
    url: url_UpdateClassifier_774909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_774922 = ref object of OpenApiRestCall_772597
proc url_UpdateConnection_774924(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateConnection_774923(path: JsonNode; query: JsonNode;
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
  var valid_774925 = header.getOrDefault("X-Amz-Date")
  valid_774925 = validateParameter(valid_774925, JString, required = false,
                                 default = nil)
  if valid_774925 != nil:
    section.add "X-Amz-Date", valid_774925
  var valid_774926 = header.getOrDefault("X-Amz-Security-Token")
  valid_774926 = validateParameter(valid_774926, JString, required = false,
                                 default = nil)
  if valid_774926 != nil:
    section.add "X-Amz-Security-Token", valid_774926
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774927 = header.getOrDefault("X-Amz-Target")
  valid_774927 = validateParameter(valid_774927, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_774927 != nil:
    section.add "X-Amz-Target", valid_774927
  var valid_774928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774928 = validateParameter(valid_774928, JString, required = false,
                                 default = nil)
  if valid_774928 != nil:
    section.add "X-Amz-Content-Sha256", valid_774928
  var valid_774929 = header.getOrDefault("X-Amz-Algorithm")
  valid_774929 = validateParameter(valid_774929, JString, required = false,
                                 default = nil)
  if valid_774929 != nil:
    section.add "X-Amz-Algorithm", valid_774929
  var valid_774930 = header.getOrDefault("X-Amz-Signature")
  valid_774930 = validateParameter(valid_774930, JString, required = false,
                                 default = nil)
  if valid_774930 != nil:
    section.add "X-Amz-Signature", valid_774930
  var valid_774931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774931 = validateParameter(valid_774931, JString, required = false,
                                 default = nil)
  if valid_774931 != nil:
    section.add "X-Amz-SignedHeaders", valid_774931
  var valid_774932 = header.getOrDefault("X-Amz-Credential")
  valid_774932 = validateParameter(valid_774932, JString, required = false,
                                 default = nil)
  if valid_774932 != nil:
    section.add "X-Amz-Credential", valid_774932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774934: Call_UpdateConnection_774922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_774934.validator(path, query, header, formData, body)
  let scheme = call_774934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774934.url(scheme.get, call_774934.host, call_774934.base,
                         call_774934.route, valid.getOrDefault("path"))
  result = hook(call_774934, url, valid)

proc call*(call_774935: Call_UpdateConnection_774922; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_774936 = newJObject()
  if body != nil:
    body_774936 = body
  result = call_774935.call(nil, nil, nil, nil, body_774936)

var updateConnection* = Call_UpdateConnection_774922(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_774923, base: "/",
    url: url_UpdateConnection_774924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_774937 = ref object of OpenApiRestCall_772597
proc url_UpdateCrawler_774939(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateCrawler_774938(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774940 = header.getOrDefault("X-Amz-Date")
  valid_774940 = validateParameter(valid_774940, JString, required = false,
                                 default = nil)
  if valid_774940 != nil:
    section.add "X-Amz-Date", valid_774940
  var valid_774941 = header.getOrDefault("X-Amz-Security-Token")
  valid_774941 = validateParameter(valid_774941, JString, required = false,
                                 default = nil)
  if valid_774941 != nil:
    section.add "X-Amz-Security-Token", valid_774941
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774942 = header.getOrDefault("X-Amz-Target")
  valid_774942 = validateParameter(valid_774942, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_774942 != nil:
    section.add "X-Amz-Target", valid_774942
  var valid_774943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774943 = validateParameter(valid_774943, JString, required = false,
                                 default = nil)
  if valid_774943 != nil:
    section.add "X-Amz-Content-Sha256", valid_774943
  var valid_774944 = header.getOrDefault("X-Amz-Algorithm")
  valid_774944 = validateParameter(valid_774944, JString, required = false,
                                 default = nil)
  if valid_774944 != nil:
    section.add "X-Amz-Algorithm", valid_774944
  var valid_774945 = header.getOrDefault("X-Amz-Signature")
  valid_774945 = validateParameter(valid_774945, JString, required = false,
                                 default = nil)
  if valid_774945 != nil:
    section.add "X-Amz-Signature", valid_774945
  var valid_774946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774946 = validateParameter(valid_774946, JString, required = false,
                                 default = nil)
  if valid_774946 != nil:
    section.add "X-Amz-SignedHeaders", valid_774946
  var valid_774947 = header.getOrDefault("X-Amz-Credential")
  valid_774947 = validateParameter(valid_774947, JString, required = false,
                                 default = nil)
  if valid_774947 != nil:
    section.add "X-Amz-Credential", valid_774947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774949: Call_UpdateCrawler_774937; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_774949.validator(path, query, header, formData, body)
  let scheme = call_774949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774949.url(scheme.get, call_774949.host, call_774949.base,
                         call_774949.route, valid.getOrDefault("path"))
  result = hook(call_774949, url, valid)

proc call*(call_774950: Call_UpdateCrawler_774937; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_774951 = newJObject()
  if body != nil:
    body_774951 = body
  result = call_774950.call(nil, nil, nil, nil, body_774951)

var updateCrawler* = Call_UpdateCrawler_774937(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_774938, base: "/", url: url_UpdateCrawler_774939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_774952 = ref object of OpenApiRestCall_772597
proc url_UpdateCrawlerSchedule_774954(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateCrawlerSchedule_774953(path: JsonNode; query: JsonNode;
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
  var valid_774955 = header.getOrDefault("X-Amz-Date")
  valid_774955 = validateParameter(valid_774955, JString, required = false,
                                 default = nil)
  if valid_774955 != nil:
    section.add "X-Amz-Date", valid_774955
  var valid_774956 = header.getOrDefault("X-Amz-Security-Token")
  valid_774956 = validateParameter(valid_774956, JString, required = false,
                                 default = nil)
  if valid_774956 != nil:
    section.add "X-Amz-Security-Token", valid_774956
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774957 = header.getOrDefault("X-Amz-Target")
  valid_774957 = validateParameter(valid_774957, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_774957 != nil:
    section.add "X-Amz-Target", valid_774957
  var valid_774958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774958 = validateParameter(valid_774958, JString, required = false,
                                 default = nil)
  if valid_774958 != nil:
    section.add "X-Amz-Content-Sha256", valid_774958
  var valid_774959 = header.getOrDefault("X-Amz-Algorithm")
  valid_774959 = validateParameter(valid_774959, JString, required = false,
                                 default = nil)
  if valid_774959 != nil:
    section.add "X-Amz-Algorithm", valid_774959
  var valid_774960 = header.getOrDefault("X-Amz-Signature")
  valid_774960 = validateParameter(valid_774960, JString, required = false,
                                 default = nil)
  if valid_774960 != nil:
    section.add "X-Amz-Signature", valid_774960
  var valid_774961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774961 = validateParameter(valid_774961, JString, required = false,
                                 default = nil)
  if valid_774961 != nil:
    section.add "X-Amz-SignedHeaders", valid_774961
  var valid_774962 = header.getOrDefault("X-Amz-Credential")
  valid_774962 = validateParameter(valid_774962, JString, required = false,
                                 default = nil)
  if valid_774962 != nil:
    section.add "X-Amz-Credential", valid_774962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774964: Call_UpdateCrawlerSchedule_774952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_774964.validator(path, query, header, formData, body)
  let scheme = call_774964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774964.url(scheme.get, call_774964.host, call_774964.base,
                         call_774964.route, valid.getOrDefault("path"))
  result = hook(call_774964, url, valid)

proc call*(call_774965: Call_UpdateCrawlerSchedule_774952; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_774966 = newJObject()
  if body != nil:
    body_774966 = body
  result = call_774965.call(nil, nil, nil, nil, body_774966)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_774952(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_774953, base: "/",
    url: url_UpdateCrawlerSchedule_774954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_774967 = ref object of OpenApiRestCall_772597
proc url_UpdateDatabase_774969(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDatabase_774968(path: JsonNode; query: JsonNode;
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
  var valid_774970 = header.getOrDefault("X-Amz-Date")
  valid_774970 = validateParameter(valid_774970, JString, required = false,
                                 default = nil)
  if valid_774970 != nil:
    section.add "X-Amz-Date", valid_774970
  var valid_774971 = header.getOrDefault("X-Amz-Security-Token")
  valid_774971 = validateParameter(valid_774971, JString, required = false,
                                 default = nil)
  if valid_774971 != nil:
    section.add "X-Amz-Security-Token", valid_774971
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774972 = header.getOrDefault("X-Amz-Target")
  valid_774972 = validateParameter(valid_774972, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_774972 != nil:
    section.add "X-Amz-Target", valid_774972
  var valid_774973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774973 = validateParameter(valid_774973, JString, required = false,
                                 default = nil)
  if valid_774973 != nil:
    section.add "X-Amz-Content-Sha256", valid_774973
  var valid_774974 = header.getOrDefault("X-Amz-Algorithm")
  valid_774974 = validateParameter(valid_774974, JString, required = false,
                                 default = nil)
  if valid_774974 != nil:
    section.add "X-Amz-Algorithm", valid_774974
  var valid_774975 = header.getOrDefault("X-Amz-Signature")
  valid_774975 = validateParameter(valid_774975, JString, required = false,
                                 default = nil)
  if valid_774975 != nil:
    section.add "X-Amz-Signature", valid_774975
  var valid_774976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774976 = validateParameter(valid_774976, JString, required = false,
                                 default = nil)
  if valid_774976 != nil:
    section.add "X-Amz-SignedHeaders", valid_774976
  var valid_774977 = header.getOrDefault("X-Amz-Credential")
  valid_774977 = validateParameter(valid_774977, JString, required = false,
                                 default = nil)
  if valid_774977 != nil:
    section.add "X-Amz-Credential", valid_774977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774979: Call_UpdateDatabase_774967; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_774979.validator(path, query, header, formData, body)
  let scheme = call_774979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774979.url(scheme.get, call_774979.host, call_774979.base,
                         call_774979.route, valid.getOrDefault("path"))
  result = hook(call_774979, url, valid)

proc call*(call_774980: Call_UpdateDatabase_774967; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_774981 = newJObject()
  if body != nil:
    body_774981 = body
  result = call_774980.call(nil, nil, nil, nil, body_774981)

var updateDatabase* = Call_UpdateDatabase_774967(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_774968, base: "/", url: url_UpdateDatabase_774969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_774982 = ref object of OpenApiRestCall_772597
proc url_UpdateDevEndpoint_774984(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDevEndpoint_774983(path: JsonNode; query: JsonNode;
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
  var valid_774985 = header.getOrDefault("X-Amz-Date")
  valid_774985 = validateParameter(valid_774985, JString, required = false,
                                 default = nil)
  if valid_774985 != nil:
    section.add "X-Amz-Date", valid_774985
  var valid_774986 = header.getOrDefault("X-Amz-Security-Token")
  valid_774986 = validateParameter(valid_774986, JString, required = false,
                                 default = nil)
  if valid_774986 != nil:
    section.add "X-Amz-Security-Token", valid_774986
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_774987 = header.getOrDefault("X-Amz-Target")
  valid_774987 = validateParameter(valid_774987, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_774987 != nil:
    section.add "X-Amz-Target", valid_774987
  var valid_774988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774988 = validateParameter(valid_774988, JString, required = false,
                                 default = nil)
  if valid_774988 != nil:
    section.add "X-Amz-Content-Sha256", valid_774988
  var valid_774989 = header.getOrDefault("X-Amz-Algorithm")
  valid_774989 = validateParameter(valid_774989, JString, required = false,
                                 default = nil)
  if valid_774989 != nil:
    section.add "X-Amz-Algorithm", valid_774989
  var valid_774990 = header.getOrDefault("X-Amz-Signature")
  valid_774990 = validateParameter(valid_774990, JString, required = false,
                                 default = nil)
  if valid_774990 != nil:
    section.add "X-Amz-Signature", valid_774990
  var valid_774991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774991 = validateParameter(valid_774991, JString, required = false,
                                 default = nil)
  if valid_774991 != nil:
    section.add "X-Amz-SignedHeaders", valid_774991
  var valid_774992 = header.getOrDefault("X-Amz-Credential")
  valid_774992 = validateParameter(valid_774992, JString, required = false,
                                 default = nil)
  if valid_774992 != nil:
    section.add "X-Amz-Credential", valid_774992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774994: Call_UpdateDevEndpoint_774982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_774994.validator(path, query, header, formData, body)
  let scheme = call_774994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774994.url(scheme.get, call_774994.host, call_774994.base,
                         call_774994.route, valid.getOrDefault("path"))
  result = hook(call_774994, url, valid)

proc call*(call_774995: Call_UpdateDevEndpoint_774982; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_774996 = newJObject()
  if body != nil:
    body_774996 = body
  result = call_774995.call(nil, nil, nil, nil, body_774996)

var updateDevEndpoint* = Call_UpdateDevEndpoint_774982(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_774983, base: "/",
    url: url_UpdateDevEndpoint_774984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_774997 = ref object of OpenApiRestCall_772597
proc url_UpdateJob_774999(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateJob_774998(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775000 = header.getOrDefault("X-Amz-Date")
  valid_775000 = validateParameter(valid_775000, JString, required = false,
                                 default = nil)
  if valid_775000 != nil:
    section.add "X-Amz-Date", valid_775000
  var valid_775001 = header.getOrDefault("X-Amz-Security-Token")
  valid_775001 = validateParameter(valid_775001, JString, required = false,
                                 default = nil)
  if valid_775001 != nil:
    section.add "X-Amz-Security-Token", valid_775001
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775002 = header.getOrDefault("X-Amz-Target")
  valid_775002 = validateParameter(valid_775002, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_775002 != nil:
    section.add "X-Amz-Target", valid_775002
  var valid_775003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775003 = validateParameter(valid_775003, JString, required = false,
                                 default = nil)
  if valid_775003 != nil:
    section.add "X-Amz-Content-Sha256", valid_775003
  var valid_775004 = header.getOrDefault("X-Amz-Algorithm")
  valid_775004 = validateParameter(valid_775004, JString, required = false,
                                 default = nil)
  if valid_775004 != nil:
    section.add "X-Amz-Algorithm", valid_775004
  var valid_775005 = header.getOrDefault("X-Amz-Signature")
  valid_775005 = validateParameter(valid_775005, JString, required = false,
                                 default = nil)
  if valid_775005 != nil:
    section.add "X-Amz-Signature", valid_775005
  var valid_775006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775006 = validateParameter(valid_775006, JString, required = false,
                                 default = nil)
  if valid_775006 != nil:
    section.add "X-Amz-SignedHeaders", valid_775006
  var valid_775007 = header.getOrDefault("X-Amz-Credential")
  valid_775007 = validateParameter(valid_775007, JString, required = false,
                                 default = nil)
  if valid_775007 != nil:
    section.add "X-Amz-Credential", valid_775007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775009: Call_UpdateJob_774997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_775009.validator(path, query, header, formData, body)
  let scheme = call_775009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775009.url(scheme.get, call_775009.host, call_775009.base,
                         call_775009.route, valid.getOrDefault("path"))
  result = hook(call_775009, url, valid)

proc call*(call_775010: Call_UpdateJob_774997; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_775011 = newJObject()
  if body != nil:
    body_775011 = body
  result = call_775010.call(nil, nil, nil, nil, body_775011)

var updateJob* = Call_UpdateJob_774997(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_774998,
                                    base: "/", url: url_UpdateJob_774999,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_775012 = ref object of OpenApiRestCall_772597
proc url_UpdateMLTransform_775014(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateMLTransform_775013(path: JsonNode; query: JsonNode;
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
  var valid_775015 = header.getOrDefault("X-Amz-Date")
  valid_775015 = validateParameter(valid_775015, JString, required = false,
                                 default = nil)
  if valid_775015 != nil:
    section.add "X-Amz-Date", valid_775015
  var valid_775016 = header.getOrDefault("X-Amz-Security-Token")
  valid_775016 = validateParameter(valid_775016, JString, required = false,
                                 default = nil)
  if valid_775016 != nil:
    section.add "X-Amz-Security-Token", valid_775016
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775017 = header.getOrDefault("X-Amz-Target")
  valid_775017 = validateParameter(valid_775017, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_775017 != nil:
    section.add "X-Amz-Target", valid_775017
  var valid_775018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775018 = validateParameter(valid_775018, JString, required = false,
                                 default = nil)
  if valid_775018 != nil:
    section.add "X-Amz-Content-Sha256", valid_775018
  var valid_775019 = header.getOrDefault("X-Amz-Algorithm")
  valid_775019 = validateParameter(valid_775019, JString, required = false,
                                 default = nil)
  if valid_775019 != nil:
    section.add "X-Amz-Algorithm", valid_775019
  var valid_775020 = header.getOrDefault("X-Amz-Signature")
  valid_775020 = validateParameter(valid_775020, JString, required = false,
                                 default = nil)
  if valid_775020 != nil:
    section.add "X-Amz-Signature", valid_775020
  var valid_775021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775021 = validateParameter(valid_775021, JString, required = false,
                                 default = nil)
  if valid_775021 != nil:
    section.add "X-Amz-SignedHeaders", valid_775021
  var valid_775022 = header.getOrDefault("X-Amz-Credential")
  valid_775022 = validateParameter(valid_775022, JString, required = false,
                                 default = nil)
  if valid_775022 != nil:
    section.add "X-Amz-Credential", valid_775022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775024: Call_UpdateMLTransform_775012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_775024.validator(path, query, header, formData, body)
  let scheme = call_775024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775024.url(scheme.get, call_775024.host, call_775024.base,
                         call_775024.route, valid.getOrDefault("path"))
  result = hook(call_775024, url, valid)

proc call*(call_775025: Call_UpdateMLTransform_775012; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_775026 = newJObject()
  if body != nil:
    body_775026 = body
  result = call_775025.call(nil, nil, nil, nil, body_775026)

var updateMLTransform* = Call_UpdateMLTransform_775012(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_775013, base: "/",
    url: url_UpdateMLTransform_775014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_775027 = ref object of OpenApiRestCall_772597
proc url_UpdatePartition_775029(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePartition_775028(path: JsonNode; query: JsonNode;
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
  var valid_775030 = header.getOrDefault("X-Amz-Date")
  valid_775030 = validateParameter(valid_775030, JString, required = false,
                                 default = nil)
  if valid_775030 != nil:
    section.add "X-Amz-Date", valid_775030
  var valid_775031 = header.getOrDefault("X-Amz-Security-Token")
  valid_775031 = validateParameter(valid_775031, JString, required = false,
                                 default = nil)
  if valid_775031 != nil:
    section.add "X-Amz-Security-Token", valid_775031
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775032 = header.getOrDefault("X-Amz-Target")
  valid_775032 = validateParameter(valid_775032, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_775032 != nil:
    section.add "X-Amz-Target", valid_775032
  var valid_775033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775033 = validateParameter(valid_775033, JString, required = false,
                                 default = nil)
  if valid_775033 != nil:
    section.add "X-Amz-Content-Sha256", valid_775033
  var valid_775034 = header.getOrDefault("X-Amz-Algorithm")
  valid_775034 = validateParameter(valid_775034, JString, required = false,
                                 default = nil)
  if valid_775034 != nil:
    section.add "X-Amz-Algorithm", valid_775034
  var valid_775035 = header.getOrDefault("X-Amz-Signature")
  valid_775035 = validateParameter(valid_775035, JString, required = false,
                                 default = nil)
  if valid_775035 != nil:
    section.add "X-Amz-Signature", valid_775035
  var valid_775036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775036 = validateParameter(valid_775036, JString, required = false,
                                 default = nil)
  if valid_775036 != nil:
    section.add "X-Amz-SignedHeaders", valid_775036
  var valid_775037 = header.getOrDefault("X-Amz-Credential")
  valid_775037 = validateParameter(valid_775037, JString, required = false,
                                 default = nil)
  if valid_775037 != nil:
    section.add "X-Amz-Credential", valid_775037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775039: Call_UpdatePartition_775027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_775039.validator(path, query, header, formData, body)
  let scheme = call_775039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775039.url(scheme.get, call_775039.host, call_775039.base,
                         call_775039.route, valid.getOrDefault("path"))
  result = hook(call_775039, url, valid)

proc call*(call_775040: Call_UpdatePartition_775027; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_775041 = newJObject()
  if body != nil:
    body_775041 = body
  result = call_775040.call(nil, nil, nil, nil, body_775041)

var updatePartition* = Call_UpdatePartition_775027(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_775028, base: "/", url: url_UpdatePartition_775029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_775042 = ref object of OpenApiRestCall_772597
proc url_UpdateTable_775044(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTable_775043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775045 = header.getOrDefault("X-Amz-Date")
  valid_775045 = validateParameter(valid_775045, JString, required = false,
                                 default = nil)
  if valid_775045 != nil:
    section.add "X-Amz-Date", valid_775045
  var valid_775046 = header.getOrDefault("X-Amz-Security-Token")
  valid_775046 = validateParameter(valid_775046, JString, required = false,
                                 default = nil)
  if valid_775046 != nil:
    section.add "X-Amz-Security-Token", valid_775046
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775047 = header.getOrDefault("X-Amz-Target")
  valid_775047 = validateParameter(valid_775047, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_775047 != nil:
    section.add "X-Amz-Target", valid_775047
  var valid_775048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775048 = validateParameter(valid_775048, JString, required = false,
                                 default = nil)
  if valid_775048 != nil:
    section.add "X-Amz-Content-Sha256", valid_775048
  var valid_775049 = header.getOrDefault("X-Amz-Algorithm")
  valid_775049 = validateParameter(valid_775049, JString, required = false,
                                 default = nil)
  if valid_775049 != nil:
    section.add "X-Amz-Algorithm", valid_775049
  var valid_775050 = header.getOrDefault("X-Amz-Signature")
  valid_775050 = validateParameter(valid_775050, JString, required = false,
                                 default = nil)
  if valid_775050 != nil:
    section.add "X-Amz-Signature", valid_775050
  var valid_775051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775051 = validateParameter(valid_775051, JString, required = false,
                                 default = nil)
  if valid_775051 != nil:
    section.add "X-Amz-SignedHeaders", valid_775051
  var valid_775052 = header.getOrDefault("X-Amz-Credential")
  valid_775052 = validateParameter(valid_775052, JString, required = false,
                                 default = nil)
  if valid_775052 != nil:
    section.add "X-Amz-Credential", valid_775052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775054: Call_UpdateTable_775042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_775054.validator(path, query, header, formData, body)
  let scheme = call_775054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775054.url(scheme.get, call_775054.host, call_775054.base,
                         call_775054.route, valid.getOrDefault("path"))
  result = hook(call_775054, url, valid)

proc call*(call_775055: Call_UpdateTable_775042; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_775056 = newJObject()
  if body != nil:
    body_775056 = body
  result = call_775055.call(nil, nil, nil, nil, body_775056)

var updateTable* = Call_UpdateTable_775042(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_775043,
                                        base: "/", url: url_UpdateTable_775044,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_775057 = ref object of OpenApiRestCall_772597
proc url_UpdateTrigger_775059(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTrigger_775058(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_775060 = header.getOrDefault("X-Amz-Date")
  valid_775060 = validateParameter(valid_775060, JString, required = false,
                                 default = nil)
  if valid_775060 != nil:
    section.add "X-Amz-Date", valid_775060
  var valid_775061 = header.getOrDefault("X-Amz-Security-Token")
  valid_775061 = validateParameter(valid_775061, JString, required = false,
                                 default = nil)
  if valid_775061 != nil:
    section.add "X-Amz-Security-Token", valid_775061
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775062 = header.getOrDefault("X-Amz-Target")
  valid_775062 = validateParameter(valid_775062, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_775062 != nil:
    section.add "X-Amz-Target", valid_775062
  var valid_775063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775063 = validateParameter(valid_775063, JString, required = false,
                                 default = nil)
  if valid_775063 != nil:
    section.add "X-Amz-Content-Sha256", valid_775063
  var valid_775064 = header.getOrDefault("X-Amz-Algorithm")
  valid_775064 = validateParameter(valid_775064, JString, required = false,
                                 default = nil)
  if valid_775064 != nil:
    section.add "X-Amz-Algorithm", valid_775064
  var valid_775065 = header.getOrDefault("X-Amz-Signature")
  valid_775065 = validateParameter(valid_775065, JString, required = false,
                                 default = nil)
  if valid_775065 != nil:
    section.add "X-Amz-Signature", valid_775065
  var valid_775066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775066 = validateParameter(valid_775066, JString, required = false,
                                 default = nil)
  if valid_775066 != nil:
    section.add "X-Amz-SignedHeaders", valid_775066
  var valid_775067 = header.getOrDefault("X-Amz-Credential")
  valid_775067 = validateParameter(valid_775067, JString, required = false,
                                 default = nil)
  if valid_775067 != nil:
    section.add "X-Amz-Credential", valid_775067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775069: Call_UpdateTrigger_775057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_775069.validator(path, query, header, formData, body)
  let scheme = call_775069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775069.url(scheme.get, call_775069.host, call_775069.base,
                         call_775069.route, valid.getOrDefault("path"))
  result = hook(call_775069, url, valid)

proc call*(call_775070: Call_UpdateTrigger_775057; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_775071 = newJObject()
  if body != nil:
    body_775071 = body
  result = call_775070.call(nil, nil, nil, nil, body_775071)

var updateTrigger* = Call_UpdateTrigger_775057(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_775058, base: "/", url: url_UpdateTrigger_775059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_775072 = ref object of OpenApiRestCall_772597
proc url_UpdateUserDefinedFunction_775074(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUserDefinedFunction_775073(path: JsonNode; query: JsonNode;
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
  var valid_775075 = header.getOrDefault("X-Amz-Date")
  valid_775075 = validateParameter(valid_775075, JString, required = false,
                                 default = nil)
  if valid_775075 != nil:
    section.add "X-Amz-Date", valid_775075
  var valid_775076 = header.getOrDefault("X-Amz-Security-Token")
  valid_775076 = validateParameter(valid_775076, JString, required = false,
                                 default = nil)
  if valid_775076 != nil:
    section.add "X-Amz-Security-Token", valid_775076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775077 = header.getOrDefault("X-Amz-Target")
  valid_775077 = validateParameter(valid_775077, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_775077 != nil:
    section.add "X-Amz-Target", valid_775077
  var valid_775078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775078 = validateParameter(valid_775078, JString, required = false,
                                 default = nil)
  if valid_775078 != nil:
    section.add "X-Amz-Content-Sha256", valid_775078
  var valid_775079 = header.getOrDefault("X-Amz-Algorithm")
  valid_775079 = validateParameter(valid_775079, JString, required = false,
                                 default = nil)
  if valid_775079 != nil:
    section.add "X-Amz-Algorithm", valid_775079
  var valid_775080 = header.getOrDefault("X-Amz-Signature")
  valid_775080 = validateParameter(valid_775080, JString, required = false,
                                 default = nil)
  if valid_775080 != nil:
    section.add "X-Amz-Signature", valid_775080
  var valid_775081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775081 = validateParameter(valid_775081, JString, required = false,
                                 default = nil)
  if valid_775081 != nil:
    section.add "X-Amz-SignedHeaders", valid_775081
  var valid_775082 = header.getOrDefault("X-Amz-Credential")
  valid_775082 = validateParameter(valid_775082, JString, required = false,
                                 default = nil)
  if valid_775082 != nil:
    section.add "X-Amz-Credential", valid_775082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775084: Call_UpdateUserDefinedFunction_775072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_775084.validator(path, query, header, formData, body)
  let scheme = call_775084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775084.url(scheme.get, call_775084.host, call_775084.base,
                         call_775084.route, valid.getOrDefault("path"))
  result = hook(call_775084, url, valid)

proc call*(call_775085: Call_UpdateUserDefinedFunction_775072; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_775086 = newJObject()
  if body != nil:
    body_775086 = body
  result = call_775085.call(nil, nil, nil, nil, body_775086)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_775072(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_775073, base: "/",
    url: url_UpdateUserDefinedFunction_775074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_775087 = ref object of OpenApiRestCall_772597
proc url_UpdateWorkflow_775089(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateWorkflow_775088(path: JsonNode; query: JsonNode;
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
  var valid_775090 = header.getOrDefault("X-Amz-Date")
  valid_775090 = validateParameter(valid_775090, JString, required = false,
                                 default = nil)
  if valid_775090 != nil:
    section.add "X-Amz-Date", valid_775090
  var valid_775091 = header.getOrDefault("X-Amz-Security-Token")
  valid_775091 = validateParameter(valid_775091, JString, required = false,
                                 default = nil)
  if valid_775091 != nil:
    section.add "X-Amz-Security-Token", valid_775091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_775092 = header.getOrDefault("X-Amz-Target")
  valid_775092 = validateParameter(valid_775092, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_775092 != nil:
    section.add "X-Amz-Target", valid_775092
  var valid_775093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775093 = validateParameter(valid_775093, JString, required = false,
                                 default = nil)
  if valid_775093 != nil:
    section.add "X-Amz-Content-Sha256", valid_775093
  var valid_775094 = header.getOrDefault("X-Amz-Algorithm")
  valid_775094 = validateParameter(valid_775094, JString, required = false,
                                 default = nil)
  if valid_775094 != nil:
    section.add "X-Amz-Algorithm", valid_775094
  var valid_775095 = header.getOrDefault("X-Amz-Signature")
  valid_775095 = validateParameter(valid_775095, JString, required = false,
                                 default = nil)
  if valid_775095 != nil:
    section.add "X-Amz-Signature", valid_775095
  var valid_775096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775096 = validateParameter(valid_775096, JString, required = false,
                                 default = nil)
  if valid_775096 != nil:
    section.add "X-Amz-SignedHeaders", valid_775096
  var valid_775097 = header.getOrDefault("X-Amz-Credential")
  valid_775097 = validateParameter(valid_775097, JString, required = false,
                                 default = nil)
  if valid_775097 != nil:
    section.add "X-Amz-Credential", valid_775097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_775099: Call_UpdateWorkflow_775087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_775099.validator(path, query, header, formData, body)
  let scheme = call_775099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775099.url(scheme.get, call_775099.host, call_775099.base,
                         call_775099.route, valid.getOrDefault("path"))
  result = hook(call_775099, url, valid)

proc call*(call_775100: Call_UpdateWorkflow_775087; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_775101 = newJObject()
  if body != nil:
    body_775101 = body
  result = call_775100.call(nil, nil, nil, nil, body_775101)

var updateWorkflow* = Call_UpdateWorkflow_775087(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_775088, base: "/", url: url_UpdateWorkflow_775089,
    schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

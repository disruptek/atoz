
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_592703 = ref object of OpenApiRestCall_592364
proc url_BatchCreatePartition_592705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchCreatePartition_592704(path: JsonNode; query: JsonNode;
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
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "AWSGlue.BatchCreatePartition"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_BatchCreatePartition_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_BatchCreatePartition_592703; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var batchCreatePartition* = Call_BatchCreatePartition_592703(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_592704, base: "/",
    url: url_BatchCreatePartition_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_592972 = ref object of OpenApiRestCall_592364
proc url_BatchDeleteConnection_592974(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteConnection_592973(path: JsonNode; query: JsonNode;
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
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteConnection"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_BatchDeleteConnection_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_BatchDeleteConnection_592972; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var batchDeleteConnection* = Call_BatchDeleteConnection_592972(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_592973, base: "/",
    url: url_BatchDeleteConnection_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_592987 = ref object of OpenApiRestCall_592364
proc url_BatchDeletePartition_592989(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeletePartition_592988(path: JsonNode; query: JsonNode;
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
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "AWSGlue.BatchDeletePartition"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_BatchDeletePartition_592987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_BatchDeletePartition_592987; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var batchDeletePartition* = Call_BatchDeletePartition_592987(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_592988, base: "/",
    url: url_BatchDeletePartition_592989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_593002 = ref object of OpenApiRestCall_592364
proc url_BatchDeleteTable_593004(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTable_593003(path: JsonNode; query: JsonNode;
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
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTable"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_BatchDeleteTable_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_BatchDeleteTable_593002; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var batchDeleteTable* = Call_BatchDeleteTable_593002(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_593003, base: "/",
    url: url_BatchDeleteTable_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_593017 = ref object of OpenApiRestCall_592364
proc url_BatchDeleteTableVersion_593019(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteTableVersion_593018(path: JsonNode; query: JsonNode;
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
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "AWSGlue.BatchDeleteTableVersion"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_BatchDeleteTableVersion_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_BatchDeleteTableVersion_593017; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_593017(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_593018, base: "/",
    url: url_BatchDeleteTableVersion_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_593032 = ref object of OpenApiRestCall_592364
proc url_BatchGetCrawlers_593034(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetCrawlers_593033(path: JsonNode; query: JsonNode;
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
  var valid_593035 = header.getOrDefault("X-Amz-Target")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AWSGlue.BatchGetCrawlers"))
  if valid_593035 != nil:
    section.add "X-Amz-Target", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_BatchGetCrawlers_593032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_BatchGetCrawlers_593032; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var batchGetCrawlers* = Call_BatchGetCrawlers_593032(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_593033, base: "/",
    url: url_BatchGetCrawlers_593034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_593047 = ref object of OpenApiRestCall_592364
proc url_BatchGetDevEndpoints_593049(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetDevEndpoints_593048(path: JsonNode; query: JsonNode;
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
  var valid_593050 = header.getOrDefault("X-Amz-Target")
  valid_593050 = validateParameter(valid_593050, JString, required = true, default = newJString(
      "AWSGlue.BatchGetDevEndpoints"))
  if valid_593050 != nil:
    section.add "X-Amz-Target", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_BatchGetDevEndpoints_593047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_BatchGetDevEndpoints_593047; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_593047(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_593048, base: "/",
    url: url_BatchGetDevEndpoints_593049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_593062 = ref object of OpenApiRestCall_592364
proc url_BatchGetJobs_593064(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetJobs_593063(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593065 = header.getOrDefault("X-Amz-Target")
  valid_593065 = validateParameter(valid_593065, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
  if valid_593065 != nil:
    section.add "X-Amz-Target", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_BatchGetJobs_593062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_BatchGetJobs_593062; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var batchGetJobs* = Call_BatchGetJobs_593062(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_593063, base: "/", url: url_BatchGetJobs_593064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_593077 = ref object of OpenApiRestCall_592364
proc url_BatchGetPartition_593079(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetPartition_593078(path: JsonNode; query: JsonNode;
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
  var valid_593080 = header.getOrDefault("X-Amz-Target")
  valid_593080 = validateParameter(valid_593080, JString, required = true, default = newJString(
      "AWSGlue.BatchGetPartition"))
  if valid_593080 != nil:
    section.add "X-Amz-Target", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Signature")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Signature", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Content-Sha256", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Date")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Date", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Credential")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Credential", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Security-Token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Security-Token", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Algorithm")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Algorithm", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-SignedHeaders", valid_593087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593089: Call_BatchGetPartition_593077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_BatchGetPartition_593077; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_593091 = newJObject()
  if body != nil:
    body_593091 = body
  result = call_593090.call(nil, nil, nil, nil, body_593091)

var batchGetPartition* = Call_BatchGetPartition_593077(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_593078, base: "/",
    url: url_BatchGetPartition_593079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_593092 = ref object of OpenApiRestCall_592364
proc url_BatchGetTriggers_593094(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetTriggers_593093(path: JsonNode; query: JsonNode;
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
  var valid_593095 = header.getOrDefault("X-Amz-Target")
  valid_593095 = validateParameter(valid_593095, JString, required = true, default = newJString(
      "AWSGlue.BatchGetTriggers"))
  if valid_593095 != nil:
    section.add "X-Amz-Target", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Signature")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Signature", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Content-Sha256", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Date")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Date", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Credential")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Credential", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Security-Token")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Security-Token", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Algorithm")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Algorithm", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-SignedHeaders", valid_593102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_BatchGetTriggers_593092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_BatchGetTriggers_593092; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_593106 = newJObject()
  if body != nil:
    body_593106 = body
  result = call_593105.call(nil, nil, nil, nil, body_593106)

var batchGetTriggers* = Call_BatchGetTriggers_593092(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_593093, base: "/",
    url: url_BatchGetTriggers_593094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_593107 = ref object of OpenApiRestCall_592364
proc url_BatchGetWorkflows_593109(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetWorkflows_593108(path: JsonNode; query: JsonNode;
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
  var valid_593110 = header.getOrDefault("X-Amz-Target")
  valid_593110 = validateParameter(valid_593110, JString, required = true, default = newJString(
      "AWSGlue.BatchGetWorkflows"))
  if valid_593110 != nil:
    section.add "X-Amz-Target", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Signature")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Signature", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Content-Sha256", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Date")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Date", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Credential")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Credential", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Security-Token")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Security-Token", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Algorithm")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Algorithm", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-SignedHeaders", valid_593117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593119: Call_BatchGetWorkflows_593107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_593119.validator(path, query, header, formData, body)
  let scheme = call_593119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593119.url(scheme.get, call_593119.host, call_593119.base,
                         call_593119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593119, url, valid)

proc call*(call_593120: Call_BatchGetWorkflows_593107; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_593121 = newJObject()
  if body != nil:
    body_593121 = body
  result = call_593120.call(nil, nil, nil, nil, body_593121)

var batchGetWorkflows* = Call_BatchGetWorkflows_593107(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_593108, base: "/",
    url: url_BatchGetWorkflows_593109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_593122 = ref object of OpenApiRestCall_592364
proc url_BatchStopJobRun_593124(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchStopJobRun_593123(path: JsonNode; query: JsonNode;
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
  var valid_593125 = header.getOrDefault("X-Amz-Target")
  valid_593125 = validateParameter(valid_593125, JString, required = true, default = newJString(
      "AWSGlue.BatchStopJobRun"))
  if valid_593125 != nil:
    section.add "X-Amz-Target", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593134: Call_BatchStopJobRun_593122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_BatchStopJobRun_593122; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_593136 = newJObject()
  if body != nil:
    body_593136 = body
  result = call_593135.call(nil, nil, nil, nil, body_593136)

var batchStopJobRun* = Call_BatchStopJobRun_593122(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_593123, base: "/", url: url_BatchStopJobRun_593124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_593137 = ref object of OpenApiRestCall_592364
proc url_CancelMLTaskRun_593139(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelMLTaskRun_593138(path: JsonNode; query: JsonNode;
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
  var valid_593140 = header.getOrDefault("X-Amz-Target")
  valid_593140 = validateParameter(valid_593140, JString, required = true, default = newJString(
      "AWSGlue.CancelMLTaskRun"))
  if valid_593140 != nil:
    section.add "X-Amz-Target", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Signature")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Signature", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Content-Sha256", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Date")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Date", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Credential")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Credential", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Security-Token")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Security-Token", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Algorithm")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Algorithm", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-SignedHeaders", valid_593147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593149: Call_CancelMLTaskRun_593137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_593149.validator(path, query, header, formData, body)
  let scheme = call_593149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593149.url(scheme.get, call_593149.host, call_593149.base,
                         call_593149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593149, url, valid)

proc call*(call_593150: Call_CancelMLTaskRun_593137; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_593151 = newJObject()
  if body != nil:
    body_593151 = body
  result = call_593150.call(nil, nil, nil, nil, body_593151)

var cancelMLTaskRun* = Call_CancelMLTaskRun_593137(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_593138, base: "/", url: url_CancelMLTaskRun_593139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_593152 = ref object of OpenApiRestCall_592364
proc url_CreateClassifier_593154(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateClassifier_593153(path: JsonNode; query: JsonNode;
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
  var valid_593155 = header.getOrDefault("X-Amz-Target")
  valid_593155 = validateParameter(valid_593155, JString, required = true, default = newJString(
      "AWSGlue.CreateClassifier"))
  if valid_593155 != nil:
    section.add "X-Amz-Target", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Signature")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Signature", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Content-Sha256", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Date")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Date", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Credential")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Credential", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Security-Token")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Security-Token", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Algorithm")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Algorithm", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-SignedHeaders", valid_593162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593164: Call_CreateClassifier_593152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_CreateClassifier_593152; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_593166 = newJObject()
  if body != nil:
    body_593166 = body
  result = call_593165.call(nil, nil, nil, nil, body_593166)

var createClassifier* = Call_CreateClassifier_593152(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_593153, base: "/",
    url: url_CreateClassifier_593154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_593167 = ref object of OpenApiRestCall_592364
proc url_CreateConnection_593169(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConnection_593168(path: JsonNode; query: JsonNode;
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
  var valid_593170 = header.getOrDefault("X-Amz-Target")
  valid_593170 = validateParameter(valid_593170, JString, required = true, default = newJString(
      "AWSGlue.CreateConnection"))
  if valid_593170 != nil:
    section.add "X-Amz-Target", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Signature")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Signature", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Content-Sha256", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Date")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Date", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Credential")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Credential", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Security-Token")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Security-Token", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Algorithm")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Algorithm", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-SignedHeaders", valid_593177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_CreateConnection_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_CreateConnection_593167; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_593181 = newJObject()
  if body != nil:
    body_593181 = body
  result = call_593180.call(nil, nil, nil, nil, body_593181)

var createConnection* = Call_CreateConnection_593167(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_593168, base: "/",
    url: url_CreateConnection_593169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_593182 = ref object of OpenApiRestCall_592364
proc url_CreateCrawler_593184(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCrawler_593183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593185 = header.getOrDefault("X-Amz-Target")
  valid_593185 = validateParameter(valid_593185, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
  if valid_593185 != nil:
    section.add "X-Amz-Target", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Signature")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Signature", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Content-Sha256", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Date")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Date", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Credential")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Credential", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Security-Token")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Security-Token", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Algorithm")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Algorithm", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-SignedHeaders", valid_593192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593194: Call_CreateCrawler_593182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_593194.validator(path, query, header, formData, body)
  let scheme = call_593194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593194.url(scheme.get, call_593194.host, call_593194.base,
                         call_593194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593194, url, valid)

proc call*(call_593195: Call_CreateCrawler_593182; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_593196 = newJObject()
  if body != nil:
    body_593196 = body
  result = call_593195.call(nil, nil, nil, nil, body_593196)

var createCrawler* = Call_CreateCrawler_593182(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_593183, base: "/", url: url_CreateCrawler_593184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_593197 = ref object of OpenApiRestCall_592364
proc url_CreateDatabase_593199(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDatabase_593198(path: JsonNode; query: JsonNode;
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
  var valid_593200 = header.getOrDefault("X-Amz-Target")
  valid_593200 = validateParameter(valid_593200, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
  if valid_593200 != nil:
    section.add "X-Amz-Target", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Signature")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Signature", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Content-Sha256", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Date")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Date", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Credential")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Credential", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Security-Token")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Security-Token", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Algorithm")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Algorithm", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-SignedHeaders", valid_593207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593209: Call_CreateDatabase_593197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_593209.validator(path, query, header, formData, body)
  let scheme = call_593209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593209.url(scheme.get, call_593209.host, call_593209.base,
                         call_593209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593209, url, valid)

proc call*(call_593210: Call_CreateDatabase_593197; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_593211 = newJObject()
  if body != nil:
    body_593211 = body
  result = call_593210.call(nil, nil, nil, nil, body_593211)

var createDatabase* = Call_CreateDatabase_593197(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_593198, base: "/", url: url_CreateDatabase_593199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_593212 = ref object of OpenApiRestCall_592364
proc url_CreateDevEndpoint_593214(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDevEndpoint_593213(path: JsonNode; query: JsonNode;
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
  var valid_593215 = header.getOrDefault("X-Amz-Target")
  valid_593215 = validateParameter(valid_593215, JString, required = true, default = newJString(
      "AWSGlue.CreateDevEndpoint"))
  if valid_593215 != nil:
    section.add "X-Amz-Target", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Signature")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Signature", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Content-Sha256", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Date")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Date", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Credential")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Credential", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Security-Token")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Security-Token", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Algorithm")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Algorithm", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-SignedHeaders", valid_593222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593224: Call_CreateDevEndpoint_593212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_593224.validator(path, query, header, formData, body)
  let scheme = call_593224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593224.url(scheme.get, call_593224.host, call_593224.base,
                         call_593224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593224, url, valid)

proc call*(call_593225: Call_CreateDevEndpoint_593212; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_593226 = newJObject()
  if body != nil:
    body_593226 = body
  result = call_593225.call(nil, nil, nil, nil, body_593226)

var createDevEndpoint* = Call_CreateDevEndpoint_593212(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_593213, base: "/",
    url: url_CreateDevEndpoint_593214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_593227 = ref object of OpenApiRestCall_592364
proc url_CreateJob_593229(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_593228(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593230 = header.getOrDefault("X-Amz-Target")
  valid_593230 = validateParameter(valid_593230, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
  if valid_593230 != nil:
    section.add "X-Amz-Target", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Signature")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Signature", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Content-Sha256", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Date")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Date", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Credential")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Credential", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Security-Token")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Security-Token", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Algorithm")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Algorithm", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-SignedHeaders", valid_593237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593239: Call_CreateJob_593227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_593239.validator(path, query, header, formData, body)
  let scheme = call_593239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593239.url(scheme.get, call_593239.host, call_593239.base,
                         call_593239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593239, url, valid)

proc call*(call_593240: Call_CreateJob_593227; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_593241 = newJObject()
  if body != nil:
    body_593241 = body
  result = call_593240.call(nil, nil, nil, nil, body_593241)

var createJob* = Call_CreateJob_593227(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_593228,
                                    base: "/", url: url_CreateJob_593229,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_593242 = ref object of OpenApiRestCall_592364
proc url_CreateMLTransform_593244(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMLTransform_593243(path: JsonNode; query: JsonNode;
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
  var valid_593245 = header.getOrDefault("X-Amz-Target")
  valid_593245 = validateParameter(valid_593245, JString, required = true, default = newJString(
      "AWSGlue.CreateMLTransform"))
  if valid_593245 != nil:
    section.add "X-Amz-Target", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Signature")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Signature", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Content-Sha256", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Date")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Date", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Credential")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Credential", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Security-Token")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Security-Token", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Algorithm")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Algorithm", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-SignedHeaders", valid_593252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593254: Call_CreateMLTransform_593242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_593254.validator(path, query, header, formData, body)
  let scheme = call_593254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593254.url(scheme.get, call_593254.host, call_593254.base,
                         call_593254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593254, url, valid)

proc call*(call_593255: Call_CreateMLTransform_593242; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_593256 = newJObject()
  if body != nil:
    body_593256 = body
  result = call_593255.call(nil, nil, nil, nil, body_593256)

var createMLTransform* = Call_CreateMLTransform_593242(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_593243, base: "/",
    url: url_CreateMLTransform_593244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_593257 = ref object of OpenApiRestCall_592364
proc url_CreatePartition_593259(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePartition_593258(path: JsonNode; query: JsonNode;
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
  var valid_593260 = header.getOrDefault("X-Amz-Target")
  valid_593260 = validateParameter(valid_593260, JString, required = true, default = newJString(
      "AWSGlue.CreatePartition"))
  if valid_593260 != nil:
    section.add "X-Amz-Target", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Signature")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Signature", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Content-Sha256", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Date")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Date", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Credential")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Credential", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Security-Token")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Security-Token", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Algorithm")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Algorithm", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-SignedHeaders", valid_593267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593269: Call_CreatePartition_593257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_593269.validator(path, query, header, formData, body)
  let scheme = call_593269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593269.url(scheme.get, call_593269.host, call_593269.base,
                         call_593269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593269, url, valid)

proc call*(call_593270: Call_CreatePartition_593257; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_593271 = newJObject()
  if body != nil:
    body_593271 = body
  result = call_593270.call(nil, nil, nil, nil, body_593271)

var createPartition* = Call_CreatePartition_593257(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_593258, base: "/", url: url_CreatePartition_593259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_593272 = ref object of OpenApiRestCall_592364
proc url_CreateScript_593274(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateScript_593273(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593275 = header.getOrDefault("X-Amz-Target")
  valid_593275 = validateParameter(valid_593275, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
  if valid_593275 != nil:
    section.add "X-Amz-Target", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Signature")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Signature", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Content-Sha256", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Date")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Date", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Credential")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Credential", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Security-Token")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Security-Token", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Algorithm")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Algorithm", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-SignedHeaders", valid_593282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_CreateScript_593272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_CreateScript_593272; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_593286 = newJObject()
  if body != nil:
    body_593286 = body
  result = call_593285.call(nil, nil, nil, nil, body_593286)

var createScript* = Call_CreateScript_593272(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_593273, base: "/", url: url_CreateScript_593274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_593287 = ref object of OpenApiRestCall_592364
proc url_CreateSecurityConfiguration_593289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSecurityConfiguration_593288(path: JsonNode; query: JsonNode;
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
  var valid_593290 = header.getOrDefault("X-Amz-Target")
  valid_593290 = validateParameter(valid_593290, JString, required = true, default = newJString(
      "AWSGlue.CreateSecurityConfiguration"))
  if valid_593290 != nil:
    section.add "X-Amz-Target", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Signature")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Signature", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Content-Sha256", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Date")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Date", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Credential")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Credential", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Security-Token")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Security-Token", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Algorithm")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Algorithm", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-SignedHeaders", valid_593297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593299: Call_CreateSecurityConfiguration_593287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_593299.validator(path, query, header, formData, body)
  let scheme = call_593299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593299.url(scheme.get, call_593299.host, call_593299.base,
                         call_593299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593299, url, valid)

proc call*(call_593300: Call_CreateSecurityConfiguration_593287; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_593301 = newJObject()
  if body != nil:
    body_593301 = body
  result = call_593300.call(nil, nil, nil, nil, body_593301)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_593287(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_593288, base: "/",
    url: url_CreateSecurityConfiguration_593289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_593302 = ref object of OpenApiRestCall_592364
proc url_CreateTable_593304(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTable_593303(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593305 = header.getOrDefault("X-Amz-Target")
  valid_593305 = validateParameter(valid_593305, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_593305 != nil:
    section.add "X-Amz-Target", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Signature")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Signature", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Content-Sha256", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Date")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Date", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Credential")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Credential", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Security-Token")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Security-Token", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Algorithm")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Algorithm", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-SignedHeaders", valid_593312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593314: Call_CreateTable_593302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_CreateTable_593302; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_593316 = newJObject()
  if body != nil:
    body_593316 = body
  result = call_593315.call(nil, nil, nil, nil, body_593316)

var createTable* = Call_CreateTable_593302(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_593303,
                                        base: "/", url: url_CreateTable_593304,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_593317 = ref object of OpenApiRestCall_592364
proc url_CreateTrigger_593319(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrigger_593318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593320 = header.getOrDefault("X-Amz-Target")
  valid_593320 = validateParameter(valid_593320, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_593320 != nil:
    section.add "X-Amz-Target", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Signature")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Signature", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Content-Sha256", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Date")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Date", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Credential")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Credential", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Security-Token")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Security-Token", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Algorithm")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Algorithm", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-SignedHeaders", valid_593327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593329: Call_CreateTrigger_593317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_CreateTrigger_593317; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_593331 = newJObject()
  if body != nil:
    body_593331 = body
  result = call_593330.call(nil, nil, nil, nil, body_593331)

var createTrigger* = Call_CreateTrigger_593317(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_593318, base: "/", url: url_CreateTrigger_593319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_593332 = ref object of OpenApiRestCall_592364
proc url_CreateUserDefinedFunction_593334(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUserDefinedFunction_593333(path: JsonNode; query: JsonNode;
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
  var valid_593335 = header.getOrDefault("X-Amz-Target")
  valid_593335 = validateParameter(valid_593335, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_593335 != nil:
    section.add "X-Amz-Target", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Signature")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Signature", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Content-Sha256", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Date")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Date", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Credential")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Credential", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Security-Token")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Security-Token", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Algorithm")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Algorithm", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-SignedHeaders", valid_593342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593344: Call_CreateUserDefinedFunction_593332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_593344.validator(path, query, header, formData, body)
  let scheme = call_593344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593344.url(scheme.get, call_593344.host, call_593344.base,
                         call_593344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593344, url, valid)

proc call*(call_593345: Call_CreateUserDefinedFunction_593332; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_593346 = newJObject()
  if body != nil:
    body_593346 = body
  result = call_593345.call(nil, nil, nil, nil, body_593346)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_593332(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_593333, base: "/",
    url: url_CreateUserDefinedFunction_593334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_593347 = ref object of OpenApiRestCall_592364
proc url_CreateWorkflow_593349(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkflow_593348(path: JsonNode; query: JsonNode;
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
  var valid_593350 = header.getOrDefault("X-Amz-Target")
  valid_593350 = validateParameter(valid_593350, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_593350 != nil:
    section.add "X-Amz-Target", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Signature")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Signature", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Content-Sha256", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Date")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Date", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Credential")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Credential", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Security-Token")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Security-Token", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Algorithm")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Algorithm", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-SignedHeaders", valid_593357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593359: Call_CreateWorkflow_593347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_593359.validator(path, query, header, formData, body)
  let scheme = call_593359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593359.url(scheme.get, call_593359.host, call_593359.base,
                         call_593359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593359, url, valid)

proc call*(call_593360: Call_CreateWorkflow_593347; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_593361 = newJObject()
  if body != nil:
    body_593361 = body
  result = call_593360.call(nil, nil, nil, nil, body_593361)

var createWorkflow* = Call_CreateWorkflow_593347(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_593348, base: "/", url: url_CreateWorkflow_593349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_593362 = ref object of OpenApiRestCall_592364
proc url_DeleteClassifier_593364(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteClassifier_593363(path: JsonNode; query: JsonNode;
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
  var valid_593365 = header.getOrDefault("X-Amz-Target")
  valid_593365 = validateParameter(valid_593365, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_593365 != nil:
    section.add "X-Amz-Target", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Signature")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Signature", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Content-Sha256", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Date")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Date", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Credential")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Credential", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Security-Token")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Security-Token", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Algorithm")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Algorithm", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-SignedHeaders", valid_593372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593374: Call_DeleteClassifier_593362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_593374.validator(path, query, header, formData, body)
  let scheme = call_593374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593374.url(scheme.get, call_593374.host, call_593374.base,
                         call_593374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593374, url, valid)

proc call*(call_593375: Call_DeleteClassifier_593362; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_593376 = newJObject()
  if body != nil:
    body_593376 = body
  result = call_593375.call(nil, nil, nil, nil, body_593376)

var deleteClassifier* = Call_DeleteClassifier_593362(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_593363, base: "/",
    url: url_DeleteClassifier_593364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_593377 = ref object of OpenApiRestCall_592364
proc url_DeleteConnection_593379(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConnection_593378(path: JsonNode; query: JsonNode;
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
  var valid_593380 = header.getOrDefault("X-Amz-Target")
  valid_593380 = validateParameter(valid_593380, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_593380 != nil:
    section.add "X-Amz-Target", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Signature")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Signature", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Content-Sha256", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Date")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Date", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Credential")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Credential", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Security-Token")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Security-Token", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Algorithm")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Algorithm", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-SignedHeaders", valid_593387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593389: Call_DeleteConnection_593377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_593389.validator(path, query, header, formData, body)
  let scheme = call_593389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593389.url(scheme.get, call_593389.host, call_593389.base,
                         call_593389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593389, url, valid)

proc call*(call_593390: Call_DeleteConnection_593377; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_593391 = newJObject()
  if body != nil:
    body_593391 = body
  result = call_593390.call(nil, nil, nil, nil, body_593391)

var deleteConnection* = Call_DeleteConnection_593377(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_593378, base: "/",
    url: url_DeleteConnection_593379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_593392 = ref object of OpenApiRestCall_592364
proc url_DeleteCrawler_593394(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCrawler_593393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593395 = header.getOrDefault("X-Amz-Target")
  valid_593395 = validateParameter(valid_593395, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_593395 != nil:
    section.add "X-Amz-Target", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Signature")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Signature", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Content-Sha256", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Date")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Date", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-Credential")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Credential", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Security-Token")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Security-Token", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Algorithm")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Algorithm", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-SignedHeaders", valid_593402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593404: Call_DeleteCrawler_593392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_593404.validator(path, query, header, formData, body)
  let scheme = call_593404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593404.url(scheme.get, call_593404.host, call_593404.base,
                         call_593404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593404, url, valid)

proc call*(call_593405: Call_DeleteCrawler_593392; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_593406 = newJObject()
  if body != nil:
    body_593406 = body
  result = call_593405.call(nil, nil, nil, nil, body_593406)

var deleteCrawler* = Call_DeleteCrawler_593392(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_593393, base: "/", url: url_DeleteCrawler_593394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_593407 = ref object of OpenApiRestCall_592364
proc url_DeleteDatabase_593409(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDatabase_593408(path: JsonNode; query: JsonNode;
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
  var valid_593410 = header.getOrDefault("X-Amz-Target")
  valid_593410 = validateParameter(valid_593410, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_593410 != nil:
    section.add "X-Amz-Target", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Signature")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Signature", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Content-Sha256", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Date")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Date", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Credential")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Credential", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Security-Token")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Security-Token", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Algorithm")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Algorithm", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-SignedHeaders", valid_593417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593419: Call_DeleteDatabase_593407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_593419.validator(path, query, header, formData, body)
  let scheme = call_593419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593419.url(scheme.get, call_593419.host, call_593419.base,
                         call_593419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593419, url, valid)

proc call*(call_593420: Call_DeleteDatabase_593407; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_593421 = newJObject()
  if body != nil:
    body_593421 = body
  result = call_593420.call(nil, nil, nil, nil, body_593421)

var deleteDatabase* = Call_DeleteDatabase_593407(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_593408, base: "/", url: url_DeleteDatabase_593409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_593422 = ref object of OpenApiRestCall_592364
proc url_DeleteDevEndpoint_593424(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDevEndpoint_593423(path: JsonNode; query: JsonNode;
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
  var valid_593425 = header.getOrDefault("X-Amz-Target")
  valid_593425 = validateParameter(valid_593425, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_593425 != nil:
    section.add "X-Amz-Target", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Signature")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Signature", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Content-Sha256", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Date")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Date", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Credential")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Credential", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Security-Token")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Security-Token", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Algorithm")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Algorithm", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-SignedHeaders", valid_593432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593434: Call_DeleteDevEndpoint_593422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_593434.validator(path, query, header, formData, body)
  let scheme = call_593434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593434.url(scheme.get, call_593434.host, call_593434.base,
                         call_593434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593434, url, valid)

proc call*(call_593435: Call_DeleteDevEndpoint_593422; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_593436 = newJObject()
  if body != nil:
    body_593436 = body
  result = call_593435.call(nil, nil, nil, nil, body_593436)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_593422(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_593423, base: "/",
    url: url_DeleteDevEndpoint_593424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_593437 = ref object of OpenApiRestCall_592364
proc url_DeleteJob_593439(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteJob_593438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593440 = header.getOrDefault("X-Amz-Target")
  valid_593440 = validateParameter(valid_593440, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_593440 != nil:
    section.add "X-Amz-Target", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Signature")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Signature", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Content-Sha256", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Date")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Date", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-Credential")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Credential", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Security-Token")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Security-Token", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Algorithm")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Algorithm", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-SignedHeaders", valid_593447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593449: Call_DeleteJob_593437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_593449.validator(path, query, header, formData, body)
  let scheme = call_593449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593449.url(scheme.get, call_593449.host, call_593449.base,
                         call_593449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593449, url, valid)

proc call*(call_593450: Call_DeleteJob_593437; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_593451 = newJObject()
  if body != nil:
    body_593451 = body
  result = call_593450.call(nil, nil, nil, nil, body_593451)

var deleteJob* = Call_DeleteJob_593437(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_593438,
                                    base: "/", url: url_DeleteJob_593439,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_593452 = ref object of OpenApiRestCall_592364
proc url_DeleteMLTransform_593454(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMLTransform_593453(path: JsonNode; query: JsonNode;
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
  var valid_593455 = header.getOrDefault("X-Amz-Target")
  valid_593455 = validateParameter(valid_593455, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_593455 != nil:
    section.add "X-Amz-Target", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Signature")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Signature", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Content-Sha256", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Date")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Date", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Credential")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Credential", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Security-Token")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Security-Token", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Algorithm")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Algorithm", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-SignedHeaders", valid_593462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593464: Call_DeleteMLTransform_593452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_593464.validator(path, query, header, formData, body)
  let scheme = call_593464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593464.url(scheme.get, call_593464.host, call_593464.base,
                         call_593464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593464, url, valid)

proc call*(call_593465: Call_DeleteMLTransform_593452; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_593466 = newJObject()
  if body != nil:
    body_593466 = body
  result = call_593465.call(nil, nil, nil, nil, body_593466)

var deleteMLTransform* = Call_DeleteMLTransform_593452(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_593453, base: "/",
    url: url_DeleteMLTransform_593454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_593467 = ref object of OpenApiRestCall_592364
proc url_DeletePartition_593469(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePartition_593468(path: JsonNode; query: JsonNode;
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
  var valid_593470 = header.getOrDefault("X-Amz-Target")
  valid_593470 = validateParameter(valid_593470, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_593470 != nil:
    section.add "X-Amz-Target", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Signature")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Signature", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Content-Sha256", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Date")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Date", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Credential")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Credential", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Security-Token")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Security-Token", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Algorithm")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Algorithm", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-SignedHeaders", valid_593477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593479: Call_DeletePartition_593467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_593479.validator(path, query, header, formData, body)
  let scheme = call_593479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593479.url(scheme.get, call_593479.host, call_593479.base,
                         call_593479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593479, url, valid)

proc call*(call_593480: Call_DeletePartition_593467; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_593481 = newJObject()
  if body != nil:
    body_593481 = body
  result = call_593480.call(nil, nil, nil, nil, body_593481)

var deletePartition* = Call_DeletePartition_593467(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_593468, base: "/", url: url_DeletePartition_593469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_593482 = ref object of OpenApiRestCall_592364
proc url_DeleteResourcePolicy_593484(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourcePolicy_593483(path: JsonNode; query: JsonNode;
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
  var valid_593485 = header.getOrDefault("X-Amz-Target")
  valid_593485 = validateParameter(valid_593485, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_593485 != nil:
    section.add "X-Amz-Target", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Signature")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Signature", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Content-Sha256", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Date")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Date", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Credential")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Credential", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Security-Token")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Security-Token", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-Algorithm")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Algorithm", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-SignedHeaders", valid_593492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593494: Call_DeleteResourcePolicy_593482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_593494.validator(path, query, header, formData, body)
  let scheme = call_593494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593494.url(scheme.get, call_593494.host, call_593494.base,
                         call_593494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593494, url, valid)

proc call*(call_593495: Call_DeleteResourcePolicy_593482; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_593496 = newJObject()
  if body != nil:
    body_593496 = body
  result = call_593495.call(nil, nil, nil, nil, body_593496)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_593482(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_593483, base: "/",
    url: url_DeleteResourcePolicy_593484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_593497 = ref object of OpenApiRestCall_592364
proc url_DeleteSecurityConfiguration_593499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSecurityConfiguration_593498(path: JsonNode; query: JsonNode;
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
  var valid_593500 = header.getOrDefault("X-Amz-Target")
  valid_593500 = validateParameter(valid_593500, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_593500 != nil:
    section.add "X-Amz-Target", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Signature")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Signature", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Content-Sha256", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Date")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Date", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Credential")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Credential", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Security-Token")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Security-Token", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Algorithm")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Algorithm", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-SignedHeaders", valid_593507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593509: Call_DeleteSecurityConfiguration_593497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_593509.validator(path, query, header, formData, body)
  let scheme = call_593509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593509.url(scheme.get, call_593509.host, call_593509.base,
                         call_593509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593509, url, valid)

proc call*(call_593510: Call_DeleteSecurityConfiguration_593497; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_593511 = newJObject()
  if body != nil:
    body_593511 = body
  result = call_593510.call(nil, nil, nil, nil, body_593511)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_593497(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_593498, base: "/",
    url: url_DeleteSecurityConfiguration_593499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_593512 = ref object of OpenApiRestCall_592364
proc url_DeleteTable_593514(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTable_593513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593515 = header.getOrDefault("X-Amz-Target")
  valid_593515 = validateParameter(valid_593515, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_593515 != nil:
    section.add "X-Amz-Target", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Signature")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Signature", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Content-Sha256", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Date")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Date", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Credential")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Credential", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Security-Token")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Security-Token", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Algorithm")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Algorithm", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-SignedHeaders", valid_593522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593524: Call_DeleteTable_593512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_593524.validator(path, query, header, formData, body)
  let scheme = call_593524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593524.url(scheme.get, call_593524.host, call_593524.base,
                         call_593524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593524, url, valid)

proc call*(call_593525: Call_DeleteTable_593512; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_593526 = newJObject()
  if body != nil:
    body_593526 = body
  result = call_593525.call(nil, nil, nil, nil, body_593526)

var deleteTable* = Call_DeleteTable_593512(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_593513,
                                        base: "/", url: url_DeleteTable_593514,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_593527 = ref object of OpenApiRestCall_592364
proc url_DeleteTableVersion_593529(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTableVersion_593528(path: JsonNode; query: JsonNode;
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
  var valid_593530 = header.getOrDefault("X-Amz-Target")
  valid_593530 = validateParameter(valid_593530, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_593530 != nil:
    section.add "X-Amz-Target", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Signature")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Signature", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Content-Sha256", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Date")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Date", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Credential")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Credential", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Security-Token")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Security-Token", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Algorithm")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Algorithm", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-SignedHeaders", valid_593537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593539: Call_DeleteTableVersion_593527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_593539.validator(path, query, header, formData, body)
  let scheme = call_593539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593539.url(scheme.get, call_593539.host, call_593539.base,
                         call_593539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593539, url, valid)

proc call*(call_593540: Call_DeleteTableVersion_593527; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_593541 = newJObject()
  if body != nil:
    body_593541 = body
  result = call_593540.call(nil, nil, nil, nil, body_593541)

var deleteTableVersion* = Call_DeleteTableVersion_593527(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_593528, base: "/",
    url: url_DeleteTableVersion_593529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_593542 = ref object of OpenApiRestCall_592364
proc url_DeleteTrigger_593544(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTrigger_593543(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593545 = header.getOrDefault("X-Amz-Target")
  valid_593545 = validateParameter(valid_593545, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_593545 != nil:
    section.add "X-Amz-Target", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-Signature")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Signature", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Content-Sha256", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Date")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Date", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Credential")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Credential", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Security-Token")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Security-Token", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Algorithm")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Algorithm", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-SignedHeaders", valid_593552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593554: Call_DeleteTrigger_593542; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_593554.validator(path, query, header, formData, body)
  let scheme = call_593554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593554.url(scheme.get, call_593554.host, call_593554.base,
                         call_593554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593554, url, valid)

proc call*(call_593555: Call_DeleteTrigger_593542; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_593556 = newJObject()
  if body != nil:
    body_593556 = body
  result = call_593555.call(nil, nil, nil, nil, body_593556)

var deleteTrigger* = Call_DeleteTrigger_593542(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_593543, base: "/", url: url_DeleteTrigger_593544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_593557 = ref object of OpenApiRestCall_592364
proc url_DeleteUserDefinedFunction_593559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUserDefinedFunction_593558(path: JsonNode; query: JsonNode;
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
  var valid_593560 = header.getOrDefault("X-Amz-Target")
  valid_593560 = validateParameter(valid_593560, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_593560 != nil:
    section.add "X-Amz-Target", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Signature")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Signature", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Content-Sha256", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Date")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Date", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Credential")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Credential", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-Security-Token")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Security-Token", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Algorithm")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Algorithm", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-SignedHeaders", valid_593567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593569: Call_DeleteUserDefinedFunction_593557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_593569.validator(path, query, header, formData, body)
  let scheme = call_593569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593569.url(scheme.get, call_593569.host, call_593569.base,
                         call_593569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593569, url, valid)

proc call*(call_593570: Call_DeleteUserDefinedFunction_593557; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_593571 = newJObject()
  if body != nil:
    body_593571 = body
  result = call_593570.call(nil, nil, nil, nil, body_593571)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_593557(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_593558, base: "/",
    url: url_DeleteUserDefinedFunction_593559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_593572 = ref object of OpenApiRestCall_592364
proc url_DeleteWorkflow_593574(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkflow_593573(path: JsonNode; query: JsonNode;
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
  var valid_593575 = header.getOrDefault("X-Amz-Target")
  valid_593575 = validateParameter(valid_593575, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_593575 != nil:
    section.add "X-Amz-Target", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Signature")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Signature", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Content-Sha256", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-Date")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-Date", valid_593578
  var valid_593579 = header.getOrDefault("X-Amz-Credential")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Credential", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-Security-Token")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Security-Token", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-Algorithm")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Algorithm", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-SignedHeaders", valid_593582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593584: Call_DeleteWorkflow_593572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_593584.validator(path, query, header, formData, body)
  let scheme = call_593584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593584.url(scheme.get, call_593584.host, call_593584.base,
                         call_593584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593584, url, valid)

proc call*(call_593585: Call_DeleteWorkflow_593572; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_593586 = newJObject()
  if body != nil:
    body_593586 = body
  result = call_593585.call(nil, nil, nil, nil, body_593586)

var deleteWorkflow* = Call_DeleteWorkflow_593572(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_593573, base: "/", url: url_DeleteWorkflow_593574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_593587 = ref object of OpenApiRestCall_592364
proc url_GetCatalogImportStatus_593589(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCatalogImportStatus_593588(path: JsonNode; query: JsonNode;
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
  var valid_593590 = header.getOrDefault("X-Amz-Target")
  valid_593590 = validateParameter(valid_593590, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_593590 != nil:
    section.add "X-Amz-Target", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Signature")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Signature", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Content-Sha256", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Date")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Date", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-Credential")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Credential", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Security-Token")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Security-Token", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Algorithm")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Algorithm", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-SignedHeaders", valid_593597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593599: Call_GetCatalogImportStatus_593587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_593599.validator(path, query, header, formData, body)
  let scheme = call_593599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593599.url(scheme.get, call_593599.host, call_593599.base,
                         call_593599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593599, url, valid)

proc call*(call_593600: Call_GetCatalogImportStatus_593587; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_593601 = newJObject()
  if body != nil:
    body_593601 = body
  result = call_593600.call(nil, nil, nil, nil, body_593601)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_593587(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_593588, base: "/",
    url: url_GetCatalogImportStatus_593589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_593602 = ref object of OpenApiRestCall_592364
proc url_GetClassifier_593604(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifier_593603(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593605 = header.getOrDefault("X-Amz-Target")
  valid_593605 = validateParameter(valid_593605, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_593605 != nil:
    section.add "X-Amz-Target", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Signature")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Signature", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Content-Sha256", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Date")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Date", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Credential")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Credential", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-Security-Token")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-Security-Token", valid_593610
  var valid_593611 = header.getOrDefault("X-Amz-Algorithm")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-Algorithm", valid_593611
  var valid_593612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "X-Amz-SignedHeaders", valid_593612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593614: Call_GetClassifier_593602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_593614.validator(path, query, header, formData, body)
  let scheme = call_593614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593614.url(scheme.get, call_593614.host, call_593614.base,
                         call_593614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593614, url, valid)

proc call*(call_593615: Call_GetClassifier_593602; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_593616 = newJObject()
  if body != nil:
    body_593616 = body
  result = call_593615.call(nil, nil, nil, nil, body_593616)

var getClassifier* = Call_GetClassifier_593602(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_593603, base: "/", url: url_GetClassifier_593604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_593617 = ref object of OpenApiRestCall_592364
proc url_GetClassifiers_593619(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetClassifiers_593618(path: JsonNode; query: JsonNode;
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
  var valid_593620 = query.getOrDefault("MaxResults")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "MaxResults", valid_593620
  var valid_593621 = query.getOrDefault("NextToken")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "NextToken", valid_593621
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
  var valid_593622 = header.getOrDefault("X-Amz-Target")
  valid_593622 = validateParameter(valid_593622, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_593622 != nil:
    section.add "X-Amz-Target", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Signature")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Signature", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Content-Sha256", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Date")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Date", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Credential")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Credential", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Security-Token")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Security-Token", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Algorithm")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Algorithm", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-SignedHeaders", valid_593629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593631: Call_GetClassifiers_593617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_593631.validator(path, query, header, formData, body)
  let scheme = call_593631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593631.url(scheme.get, call_593631.host, call_593631.base,
                         call_593631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593631, url, valid)

proc call*(call_593632: Call_GetClassifiers_593617; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593633 = newJObject()
  var body_593634 = newJObject()
  add(query_593633, "MaxResults", newJString(MaxResults))
  add(query_593633, "NextToken", newJString(NextToken))
  if body != nil:
    body_593634 = body
  result = call_593632.call(nil, query_593633, nil, nil, body_593634)

var getClassifiers* = Call_GetClassifiers_593617(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_593618, base: "/", url: url_GetClassifiers_593619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_593636 = ref object of OpenApiRestCall_592364
proc url_GetConnection_593638(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnection_593637(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593639 = header.getOrDefault("X-Amz-Target")
  valid_593639 = validateParameter(valid_593639, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
  if valid_593639 != nil:
    section.add "X-Amz-Target", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Signature")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Signature", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Content-Sha256", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Date")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Date", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Credential")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Credential", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Security-Token")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Security-Token", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-Algorithm")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-Algorithm", valid_593645
  var valid_593646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593646 = validateParameter(valid_593646, JString, required = false,
                                 default = nil)
  if valid_593646 != nil:
    section.add "X-Amz-SignedHeaders", valid_593646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593648: Call_GetConnection_593636; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_593648.validator(path, query, header, formData, body)
  let scheme = call_593648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593648.url(scheme.get, call_593648.host, call_593648.base,
                         call_593648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593648, url, valid)

proc call*(call_593649: Call_GetConnection_593636; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_593650 = newJObject()
  if body != nil:
    body_593650 = body
  result = call_593649.call(nil, nil, nil, nil, body_593650)

var getConnection* = Call_GetConnection_593636(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_593637, base: "/", url: url_GetConnection_593638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_593651 = ref object of OpenApiRestCall_592364
proc url_GetConnections_593653(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnections_593652(path: JsonNode; query: JsonNode;
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
  var valid_593654 = query.getOrDefault("MaxResults")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "MaxResults", valid_593654
  var valid_593655 = query.getOrDefault("NextToken")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "NextToken", valid_593655
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
  var valid_593656 = header.getOrDefault("X-Amz-Target")
  valid_593656 = validateParameter(valid_593656, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_593656 != nil:
    section.add "X-Amz-Target", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-Signature")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Signature", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Content-Sha256", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Date")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Date", valid_593659
  var valid_593660 = header.getOrDefault("X-Amz-Credential")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "X-Amz-Credential", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Security-Token")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Security-Token", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Algorithm")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Algorithm", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-SignedHeaders", valid_593663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593665: Call_GetConnections_593651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_593665.validator(path, query, header, formData, body)
  let scheme = call_593665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593665.url(scheme.get, call_593665.host, call_593665.base,
                         call_593665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593665, url, valid)

proc call*(call_593666: Call_GetConnections_593651; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593667 = newJObject()
  var body_593668 = newJObject()
  add(query_593667, "MaxResults", newJString(MaxResults))
  add(query_593667, "NextToken", newJString(NextToken))
  if body != nil:
    body_593668 = body
  result = call_593666.call(nil, query_593667, nil, nil, body_593668)

var getConnections* = Call_GetConnections_593651(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_593652, base: "/", url: url_GetConnections_593653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_593669 = ref object of OpenApiRestCall_592364
proc url_GetCrawler_593671(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawler_593670(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593672 = header.getOrDefault("X-Amz-Target")
  valid_593672 = validateParameter(valid_593672, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_593672 != nil:
    section.add "X-Amz-Target", valid_593672
  var valid_593673 = header.getOrDefault("X-Amz-Signature")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "X-Amz-Signature", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Content-Sha256", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Date")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Date", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Credential")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Credential", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Security-Token")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Security-Token", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Algorithm")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Algorithm", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-SignedHeaders", valid_593679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593681: Call_GetCrawler_593669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_593681.validator(path, query, header, formData, body)
  let scheme = call_593681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593681.url(scheme.get, call_593681.host, call_593681.base,
                         call_593681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593681, url, valid)

proc call*(call_593682: Call_GetCrawler_593669; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_593683 = newJObject()
  if body != nil:
    body_593683 = body
  result = call_593682.call(nil, nil, nil, nil, body_593683)

var getCrawler* = Call_GetCrawler_593669(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_593670,
                                      base: "/", url: url_GetCrawler_593671,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_593684 = ref object of OpenApiRestCall_592364
proc url_GetCrawlerMetrics_593686(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlerMetrics_593685(path: JsonNode; query: JsonNode;
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
  var valid_593687 = query.getOrDefault("MaxResults")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "MaxResults", valid_593687
  var valid_593688 = query.getOrDefault("NextToken")
  valid_593688 = validateParameter(valid_593688, JString, required = false,
                                 default = nil)
  if valid_593688 != nil:
    section.add "NextToken", valid_593688
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
  var valid_593689 = header.getOrDefault("X-Amz-Target")
  valid_593689 = validateParameter(valid_593689, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_593689 != nil:
    section.add "X-Amz-Target", valid_593689
  var valid_593690 = header.getOrDefault("X-Amz-Signature")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Signature", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-Content-Sha256", valid_593691
  var valid_593692 = header.getOrDefault("X-Amz-Date")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Date", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Credential")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Credential", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Security-Token")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Security-Token", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Algorithm")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Algorithm", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-SignedHeaders", valid_593696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593698: Call_GetCrawlerMetrics_593684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_593698.validator(path, query, header, formData, body)
  let scheme = call_593698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593698.url(scheme.get, call_593698.host, call_593698.base,
                         call_593698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593698, url, valid)

proc call*(call_593699: Call_GetCrawlerMetrics_593684; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593700 = newJObject()
  var body_593701 = newJObject()
  add(query_593700, "MaxResults", newJString(MaxResults))
  add(query_593700, "NextToken", newJString(NextToken))
  if body != nil:
    body_593701 = body
  result = call_593699.call(nil, query_593700, nil, nil, body_593701)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_593684(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_593685, base: "/",
    url: url_GetCrawlerMetrics_593686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_593702 = ref object of OpenApiRestCall_592364
proc url_GetCrawlers_593704(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCrawlers_593703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593705 = query.getOrDefault("MaxResults")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "MaxResults", valid_593705
  var valid_593706 = query.getOrDefault("NextToken")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "NextToken", valid_593706
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
  var valid_593707 = header.getOrDefault("X-Amz-Target")
  valid_593707 = validateParameter(valid_593707, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_593707 != nil:
    section.add "X-Amz-Target", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Signature")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Signature", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Content-Sha256", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-Date")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Date", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-Credential")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Credential", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-Security-Token")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-Security-Token", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-Algorithm")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-Algorithm", valid_593713
  var valid_593714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593714 = validateParameter(valid_593714, JString, required = false,
                                 default = nil)
  if valid_593714 != nil:
    section.add "X-Amz-SignedHeaders", valid_593714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593716: Call_GetCrawlers_593702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_593716.validator(path, query, header, formData, body)
  let scheme = call_593716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593716.url(scheme.get, call_593716.host, call_593716.base,
                         call_593716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593716, url, valid)

proc call*(call_593717: Call_GetCrawlers_593702; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593718 = newJObject()
  var body_593719 = newJObject()
  add(query_593718, "MaxResults", newJString(MaxResults))
  add(query_593718, "NextToken", newJString(NextToken))
  if body != nil:
    body_593719 = body
  result = call_593717.call(nil, query_593718, nil, nil, body_593719)

var getCrawlers* = Call_GetCrawlers_593702(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_593703,
                                        base: "/", url: url_GetCrawlers_593704,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_593720 = ref object of OpenApiRestCall_592364
proc url_GetDataCatalogEncryptionSettings_593722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataCatalogEncryptionSettings_593721(path: JsonNode;
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
  var valid_593723 = header.getOrDefault("X-Amz-Target")
  valid_593723 = validateParameter(valid_593723, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_593723 != nil:
    section.add "X-Amz-Target", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Signature")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Signature", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Content-Sha256", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-Date")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Date", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Credential")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Credential", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Security-Token")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Security-Token", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-Algorithm")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-Algorithm", valid_593729
  var valid_593730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-SignedHeaders", valid_593730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593732: Call_GetDataCatalogEncryptionSettings_593720;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_593732.validator(path, query, header, formData, body)
  let scheme = call_593732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593732.url(scheme.get, call_593732.host, call_593732.base,
                         call_593732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593732, url, valid)

proc call*(call_593733: Call_GetDataCatalogEncryptionSettings_593720;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_593734 = newJObject()
  if body != nil:
    body_593734 = body
  result = call_593733.call(nil, nil, nil, nil, body_593734)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_593720(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_593721, base: "/",
    url: url_GetDataCatalogEncryptionSettings_593722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_593735 = ref object of OpenApiRestCall_592364
proc url_GetDatabase_593737(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabase_593736(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593738 = header.getOrDefault("X-Amz-Target")
  valid_593738 = validateParameter(valid_593738, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_593738 != nil:
    section.add "X-Amz-Target", valid_593738
  var valid_593739 = header.getOrDefault("X-Amz-Signature")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "X-Amz-Signature", valid_593739
  var valid_593740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "X-Amz-Content-Sha256", valid_593740
  var valid_593741 = header.getOrDefault("X-Amz-Date")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-Date", valid_593741
  var valid_593742 = header.getOrDefault("X-Amz-Credential")
  valid_593742 = validateParameter(valid_593742, JString, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "X-Amz-Credential", valid_593742
  var valid_593743 = header.getOrDefault("X-Amz-Security-Token")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "X-Amz-Security-Token", valid_593743
  var valid_593744 = header.getOrDefault("X-Amz-Algorithm")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-Algorithm", valid_593744
  var valid_593745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-SignedHeaders", valid_593745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593747: Call_GetDatabase_593735; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_593747.validator(path, query, header, formData, body)
  let scheme = call_593747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593747.url(scheme.get, call_593747.host, call_593747.base,
                         call_593747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593747, url, valid)

proc call*(call_593748: Call_GetDatabase_593735; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_593749 = newJObject()
  if body != nil:
    body_593749 = body
  result = call_593748.call(nil, nil, nil, nil, body_593749)

var getDatabase* = Call_GetDatabase_593735(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_593736,
                                        base: "/", url: url_GetDatabase_593737,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_593750 = ref object of OpenApiRestCall_592364
proc url_GetDatabases_593752(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDatabases_593751(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593753 = query.getOrDefault("MaxResults")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "MaxResults", valid_593753
  var valid_593754 = query.getOrDefault("NextToken")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "NextToken", valid_593754
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
  var valid_593755 = header.getOrDefault("X-Amz-Target")
  valid_593755 = validateParameter(valid_593755, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_593755 != nil:
    section.add "X-Amz-Target", valid_593755
  var valid_593756 = header.getOrDefault("X-Amz-Signature")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-Signature", valid_593756
  var valid_593757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-Content-Sha256", valid_593757
  var valid_593758 = header.getOrDefault("X-Amz-Date")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "X-Amz-Date", valid_593758
  var valid_593759 = header.getOrDefault("X-Amz-Credential")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Credential", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Security-Token")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Security-Token", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Algorithm")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Algorithm", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-SignedHeaders", valid_593762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593764: Call_GetDatabases_593750; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_593764.validator(path, query, header, formData, body)
  let scheme = call_593764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593764.url(scheme.get, call_593764.host, call_593764.base,
                         call_593764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593764, url, valid)

proc call*(call_593765: Call_GetDatabases_593750; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593766 = newJObject()
  var body_593767 = newJObject()
  add(query_593766, "MaxResults", newJString(MaxResults))
  add(query_593766, "NextToken", newJString(NextToken))
  if body != nil:
    body_593767 = body
  result = call_593765.call(nil, query_593766, nil, nil, body_593767)

var getDatabases* = Call_GetDatabases_593750(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_593751, base: "/", url: url_GetDatabases_593752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_593768 = ref object of OpenApiRestCall_592364
proc url_GetDataflowGraph_593770(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataflowGraph_593769(path: JsonNode; query: JsonNode;
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
  var valid_593771 = header.getOrDefault("X-Amz-Target")
  valid_593771 = validateParameter(valid_593771, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_593771 != nil:
    section.add "X-Amz-Target", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Signature")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Signature", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Content-Sha256", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Date")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Date", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Credential")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Credential", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Security-Token")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Security-Token", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-Algorithm")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-Algorithm", valid_593777
  var valid_593778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "X-Amz-SignedHeaders", valid_593778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593780: Call_GetDataflowGraph_593768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_593780.validator(path, query, header, formData, body)
  let scheme = call_593780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593780.url(scheme.get, call_593780.host, call_593780.base,
                         call_593780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593780, url, valid)

proc call*(call_593781: Call_GetDataflowGraph_593768; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_593782 = newJObject()
  if body != nil:
    body_593782 = body
  result = call_593781.call(nil, nil, nil, nil, body_593782)

var getDataflowGraph* = Call_GetDataflowGraph_593768(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_593769, base: "/",
    url: url_GetDataflowGraph_593770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_593783 = ref object of OpenApiRestCall_592364
proc url_GetDevEndpoint_593785(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoint_593784(path: JsonNode; query: JsonNode;
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
  var valid_593786 = header.getOrDefault("X-Amz-Target")
  valid_593786 = validateParameter(valid_593786, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_593786 != nil:
    section.add "X-Amz-Target", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-Signature")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-Signature", valid_593787
  var valid_593788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "X-Amz-Content-Sha256", valid_593788
  var valid_593789 = header.getOrDefault("X-Amz-Date")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "X-Amz-Date", valid_593789
  var valid_593790 = header.getOrDefault("X-Amz-Credential")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "X-Amz-Credential", valid_593790
  var valid_593791 = header.getOrDefault("X-Amz-Security-Token")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "X-Amz-Security-Token", valid_593791
  var valid_593792 = header.getOrDefault("X-Amz-Algorithm")
  valid_593792 = validateParameter(valid_593792, JString, required = false,
                                 default = nil)
  if valid_593792 != nil:
    section.add "X-Amz-Algorithm", valid_593792
  var valid_593793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593793 = validateParameter(valid_593793, JString, required = false,
                                 default = nil)
  if valid_593793 != nil:
    section.add "X-Amz-SignedHeaders", valid_593793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593795: Call_GetDevEndpoint_593783; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_593795.validator(path, query, header, formData, body)
  let scheme = call_593795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593795.url(scheme.get, call_593795.host, call_593795.base,
                         call_593795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593795, url, valid)

proc call*(call_593796: Call_GetDevEndpoint_593783; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_593797 = newJObject()
  if body != nil:
    body_593797 = body
  result = call_593796.call(nil, nil, nil, nil, body_593797)

var getDevEndpoint* = Call_GetDevEndpoint_593783(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_593784, base: "/", url: url_GetDevEndpoint_593785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_593798 = ref object of OpenApiRestCall_592364
proc url_GetDevEndpoints_593800(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDevEndpoints_593799(path: JsonNode; query: JsonNode;
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
  var valid_593801 = query.getOrDefault("MaxResults")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "MaxResults", valid_593801
  var valid_593802 = query.getOrDefault("NextToken")
  valid_593802 = validateParameter(valid_593802, JString, required = false,
                                 default = nil)
  if valid_593802 != nil:
    section.add "NextToken", valid_593802
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
  var valid_593803 = header.getOrDefault("X-Amz-Target")
  valid_593803 = validateParameter(valid_593803, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_593803 != nil:
    section.add "X-Amz-Target", valid_593803
  var valid_593804 = header.getOrDefault("X-Amz-Signature")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-Signature", valid_593804
  var valid_593805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Content-Sha256", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-Date")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-Date", valid_593806
  var valid_593807 = header.getOrDefault("X-Amz-Credential")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-Credential", valid_593807
  var valid_593808 = header.getOrDefault("X-Amz-Security-Token")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-Security-Token", valid_593808
  var valid_593809 = header.getOrDefault("X-Amz-Algorithm")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Algorithm", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-SignedHeaders", valid_593810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593812: Call_GetDevEndpoints_593798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_593812.validator(path, query, header, formData, body)
  let scheme = call_593812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593812.url(scheme.get, call_593812.host, call_593812.base,
                         call_593812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593812, url, valid)

proc call*(call_593813: Call_GetDevEndpoints_593798; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593814 = newJObject()
  var body_593815 = newJObject()
  add(query_593814, "MaxResults", newJString(MaxResults))
  add(query_593814, "NextToken", newJString(NextToken))
  if body != nil:
    body_593815 = body
  result = call_593813.call(nil, query_593814, nil, nil, body_593815)

var getDevEndpoints* = Call_GetDevEndpoints_593798(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_593799, base: "/", url: url_GetDevEndpoints_593800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_593816 = ref object of OpenApiRestCall_592364
proc url_GetJob_593818(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJob_593817(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593819 = header.getOrDefault("X-Amz-Target")
  valid_593819 = validateParameter(valid_593819, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_593819 != nil:
    section.add "X-Amz-Target", valid_593819
  var valid_593820 = header.getOrDefault("X-Amz-Signature")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Signature", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Content-Sha256", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-Date")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-Date", valid_593822
  var valid_593823 = header.getOrDefault("X-Amz-Credential")
  valid_593823 = validateParameter(valid_593823, JString, required = false,
                                 default = nil)
  if valid_593823 != nil:
    section.add "X-Amz-Credential", valid_593823
  var valid_593824 = header.getOrDefault("X-Amz-Security-Token")
  valid_593824 = validateParameter(valid_593824, JString, required = false,
                                 default = nil)
  if valid_593824 != nil:
    section.add "X-Amz-Security-Token", valid_593824
  var valid_593825 = header.getOrDefault("X-Amz-Algorithm")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "X-Amz-Algorithm", valid_593825
  var valid_593826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593826 = validateParameter(valid_593826, JString, required = false,
                                 default = nil)
  if valid_593826 != nil:
    section.add "X-Amz-SignedHeaders", valid_593826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593828: Call_GetJob_593816; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_593828.validator(path, query, header, formData, body)
  let scheme = call_593828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593828.url(scheme.get, call_593828.host, call_593828.base,
                         call_593828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593828, url, valid)

proc call*(call_593829: Call_GetJob_593816; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_593830 = newJObject()
  if body != nil:
    body_593830 = body
  result = call_593829.call(nil, nil, nil, nil, body_593830)

var getJob* = Call_GetJob_593816(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_593817, base: "/",
                              url: url_GetJob_593818,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_593831 = ref object of OpenApiRestCall_592364
proc url_GetJobBookmark_593833(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobBookmark_593832(path: JsonNode; query: JsonNode;
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
  var valid_593834 = header.getOrDefault("X-Amz-Target")
  valid_593834 = validateParameter(valid_593834, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_593834 != nil:
    section.add "X-Amz-Target", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Signature")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Signature", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Content-Sha256", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Date")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Date", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Credential")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Credential", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Security-Token")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Security-Token", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Algorithm")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Algorithm", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-SignedHeaders", valid_593841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593843: Call_GetJobBookmark_593831; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_593843.validator(path, query, header, formData, body)
  let scheme = call_593843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593843.url(scheme.get, call_593843.host, call_593843.base,
                         call_593843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593843, url, valid)

proc call*(call_593844: Call_GetJobBookmark_593831; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_593845 = newJObject()
  if body != nil:
    body_593845 = body
  result = call_593844.call(nil, nil, nil, nil, body_593845)

var getJobBookmark* = Call_GetJobBookmark_593831(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_593832, base: "/", url: url_GetJobBookmark_593833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_593846 = ref object of OpenApiRestCall_592364
proc url_GetJobRun_593848(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRun_593847(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593849 = header.getOrDefault("X-Amz-Target")
  valid_593849 = validateParameter(valid_593849, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_593849 != nil:
    section.add "X-Amz-Target", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Signature")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Signature", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Content-Sha256", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-Date")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Date", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Credential")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Credential", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-Security-Token")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Security-Token", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Algorithm")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Algorithm", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-SignedHeaders", valid_593856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593858: Call_GetJobRun_593846; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_593858.validator(path, query, header, formData, body)
  let scheme = call_593858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593858.url(scheme.get, call_593858.host, call_593858.base,
                         call_593858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593858, url, valid)

proc call*(call_593859: Call_GetJobRun_593846; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_593860 = newJObject()
  if body != nil:
    body_593860 = body
  result = call_593859.call(nil, nil, nil, nil, body_593860)

var getJobRun* = Call_GetJobRun_593846(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_593847,
                                    base: "/", url: url_GetJobRun_593848,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_593861 = ref object of OpenApiRestCall_592364
proc url_GetJobRuns_593863(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobRuns_593862(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593864 = query.getOrDefault("MaxResults")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "MaxResults", valid_593864
  var valid_593865 = query.getOrDefault("NextToken")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "NextToken", valid_593865
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
  var valid_593866 = header.getOrDefault("X-Amz-Target")
  valid_593866 = validateParameter(valid_593866, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_593866 != nil:
    section.add "X-Amz-Target", valid_593866
  var valid_593867 = header.getOrDefault("X-Amz-Signature")
  valid_593867 = validateParameter(valid_593867, JString, required = false,
                                 default = nil)
  if valid_593867 != nil:
    section.add "X-Amz-Signature", valid_593867
  var valid_593868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "X-Amz-Content-Sha256", valid_593868
  var valid_593869 = header.getOrDefault("X-Amz-Date")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-Date", valid_593869
  var valid_593870 = header.getOrDefault("X-Amz-Credential")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Credential", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Security-Token")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Security-Token", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Algorithm")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Algorithm", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-SignedHeaders", valid_593873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593875: Call_GetJobRuns_593861; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_593875.validator(path, query, header, formData, body)
  let scheme = call_593875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593875.url(scheme.get, call_593875.host, call_593875.base,
                         call_593875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593875, url, valid)

proc call*(call_593876: Call_GetJobRuns_593861; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593877 = newJObject()
  var body_593878 = newJObject()
  add(query_593877, "MaxResults", newJString(MaxResults))
  add(query_593877, "NextToken", newJString(NextToken))
  if body != nil:
    body_593878 = body
  result = call_593876.call(nil, query_593877, nil, nil, body_593878)

var getJobRuns* = Call_GetJobRuns_593861(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_593862,
                                      base: "/", url: url_GetJobRuns_593863,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_593879 = ref object of OpenApiRestCall_592364
proc url_GetJobs_593881(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobs_593880(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593882 = query.getOrDefault("MaxResults")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "MaxResults", valid_593882
  var valid_593883 = query.getOrDefault("NextToken")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "NextToken", valid_593883
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
  var valid_593884 = header.getOrDefault("X-Amz-Target")
  valid_593884 = validateParameter(valid_593884, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_593884 != nil:
    section.add "X-Amz-Target", valid_593884
  var valid_593885 = header.getOrDefault("X-Amz-Signature")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Signature", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Content-Sha256", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Date")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Date", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Credential")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Credential", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Algorithm")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Algorithm", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-SignedHeaders", valid_593891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593893: Call_GetJobs_593879; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_593893.validator(path, query, header, formData, body)
  let scheme = call_593893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593893.url(scheme.get, call_593893.host, call_593893.base,
                         call_593893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593893, url, valid)

proc call*(call_593894: Call_GetJobs_593879; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593895 = newJObject()
  var body_593896 = newJObject()
  add(query_593895, "MaxResults", newJString(MaxResults))
  add(query_593895, "NextToken", newJString(NextToken))
  if body != nil:
    body_593896 = body
  result = call_593894.call(nil, query_593895, nil, nil, body_593896)

var getJobs* = Call_GetJobs_593879(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_593880, base: "/",
                                url: url_GetJobs_593881,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_593897 = ref object of OpenApiRestCall_592364
proc url_GetMLTaskRun_593899(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRun_593898(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593900 = header.getOrDefault("X-Amz-Target")
  valid_593900 = validateParameter(valid_593900, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_593900 != nil:
    section.add "X-Amz-Target", valid_593900
  var valid_593901 = header.getOrDefault("X-Amz-Signature")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "X-Amz-Signature", valid_593901
  var valid_593902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "X-Amz-Content-Sha256", valid_593902
  var valid_593903 = header.getOrDefault("X-Amz-Date")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-Date", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Credential")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Credential", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Security-Token")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Security-Token", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Algorithm")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Algorithm", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593909: Call_GetMLTaskRun_593897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_593909.validator(path, query, header, formData, body)
  let scheme = call_593909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593909.url(scheme.get, call_593909.host, call_593909.base,
                         call_593909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593909, url, valid)

proc call*(call_593910: Call_GetMLTaskRun_593897; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_593911 = newJObject()
  if body != nil:
    body_593911 = body
  result = call_593910.call(nil, nil, nil, nil, body_593911)

var getMLTaskRun* = Call_GetMLTaskRun_593897(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_593898, base: "/", url: url_GetMLTaskRun_593899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_593912 = ref object of OpenApiRestCall_592364
proc url_GetMLTaskRuns_593914(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTaskRuns_593913(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593915 = query.getOrDefault("MaxResults")
  valid_593915 = validateParameter(valid_593915, JString, required = false,
                                 default = nil)
  if valid_593915 != nil:
    section.add "MaxResults", valid_593915
  var valid_593916 = query.getOrDefault("NextToken")
  valid_593916 = validateParameter(valid_593916, JString, required = false,
                                 default = nil)
  if valid_593916 != nil:
    section.add "NextToken", valid_593916
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
  var valid_593917 = header.getOrDefault("X-Amz-Target")
  valid_593917 = validateParameter(valid_593917, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_593917 != nil:
    section.add "X-Amz-Target", valid_593917
  var valid_593918 = header.getOrDefault("X-Amz-Signature")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "X-Amz-Signature", valid_593918
  var valid_593919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-Content-Sha256", valid_593919
  var valid_593920 = header.getOrDefault("X-Amz-Date")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "X-Amz-Date", valid_593920
  var valid_593921 = header.getOrDefault("X-Amz-Credential")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Credential", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-Security-Token")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Security-Token", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-Algorithm")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Algorithm", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-SignedHeaders", valid_593924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593926: Call_GetMLTaskRuns_593912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_593926.validator(path, query, header, formData, body)
  let scheme = call_593926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593926.url(scheme.get, call_593926.host, call_593926.base,
                         call_593926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593926, url, valid)

proc call*(call_593927: Call_GetMLTaskRuns_593912; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593928 = newJObject()
  var body_593929 = newJObject()
  add(query_593928, "MaxResults", newJString(MaxResults))
  add(query_593928, "NextToken", newJString(NextToken))
  if body != nil:
    body_593929 = body
  result = call_593927.call(nil, query_593928, nil, nil, body_593929)

var getMLTaskRuns* = Call_GetMLTaskRuns_593912(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_593913, base: "/", url: url_GetMLTaskRuns_593914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_593930 = ref object of OpenApiRestCall_592364
proc url_GetMLTransform_593932(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransform_593931(path: JsonNode; query: JsonNode;
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
  var valid_593933 = header.getOrDefault("X-Amz-Target")
  valid_593933 = validateParameter(valid_593933, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_593933 != nil:
    section.add "X-Amz-Target", valid_593933
  var valid_593934 = header.getOrDefault("X-Amz-Signature")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "X-Amz-Signature", valid_593934
  var valid_593935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "X-Amz-Content-Sha256", valid_593935
  var valid_593936 = header.getOrDefault("X-Amz-Date")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Date", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Credential")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Credential", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-Security-Token")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Security-Token", valid_593938
  var valid_593939 = header.getOrDefault("X-Amz-Algorithm")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "X-Amz-Algorithm", valid_593939
  var valid_593940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-SignedHeaders", valid_593940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593942: Call_GetMLTransform_593930; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_593942.validator(path, query, header, formData, body)
  let scheme = call_593942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593942.url(scheme.get, call_593942.host, call_593942.base,
                         call_593942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593942, url, valid)

proc call*(call_593943: Call_GetMLTransform_593930; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_593944 = newJObject()
  if body != nil:
    body_593944 = body
  result = call_593943.call(nil, nil, nil, nil, body_593944)

var getMLTransform* = Call_GetMLTransform_593930(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_593931, base: "/", url: url_GetMLTransform_593932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_593945 = ref object of OpenApiRestCall_592364
proc url_GetMLTransforms_593947(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLTransforms_593946(path: JsonNode; query: JsonNode;
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
  var valid_593948 = query.getOrDefault("MaxResults")
  valid_593948 = validateParameter(valid_593948, JString, required = false,
                                 default = nil)
  if valid_593948 != nil:
    section.add "MaxResults", valid_593948
  var valid_593949 = query.getOrDefault("NextToken")
  valid_593949 = validateParameter(valid_593949, JString, required = false,
                                 default = nil)
  if valid_593949 != nil:
    section.add "NextToken", valid_593949
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
  var valid_593950 = header.getOrDefault("X-Amz-Target")
  valid_593950 = validateParameter(valid_593950, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_593950 != nil:
    section.add "X-Amz-Target", valid_593950
  var valid_593951 = header.getOrDefault("X-Amz-Signature")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "X-Amz-Signature", valid_593951
  var valid_593952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "X-Amz-Content-Sha256", valid_593952
  var valid_593953 = header.getOrDefault("X-Amz-Date")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "X-Amz-Date", valid_593953
  var valid_593954 = header.getOrDefault("X-Amz-Credential")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "X-Amz-Credential", valid_593954
  var valid_593955 = header.getOrDefault("X-Amz-Security-Token")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "X-Amz-Security-Token", valid_593955
  var valid_593956 = header.getOrDefault("X-Amz-Algorithm")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "X-Amz-Algorithm", valid_593956
  var valid_593957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "X-Amz-SignedHeaders", valid_593957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593959: Call_GetMLTransforms_593945; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_593959.validator(path, query, header, formData, body)
  let scheme = call_593959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593959.url(scheme.get, call_593959.host, call_593959.base,
                         call_593959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593959, url, valid)

proc call*(call_593960: Call_GetMLTransforms_593945; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593961 = newJObject()
  var body_593962 = newJObject()
  add(query_593961, "MaxResults", newJString(MaxResults))
  add(query_593961, "NextToken", newJString(NextToken))
  if body != nil:
    body_593962 = body
  result = call_593960.call(nil, query_593961, nil, nil, body_593962)

var getMLTransforms* = Call_GetMLTransforms_593945(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_593946, base: "/", url: url_GetMLTransforms_593947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_593963 = ref object of OpenApiRestCall_592364
proc url_GetMapping_593965(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMapping_593964(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593966 = header.getOrDefault("X-Amz-Target")
  valid_593966 = validateParameter(valid_593966, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_593966 != nil:
    section.add "X-Amz-Target", valid_593966
  var valid_593967 = header.getOrDefault("X-Amz-Signature")
  valid_593967 = validateParameter(valid_593967, JString, required = false,
                                 default = nil)
  if valid_593967 != nil:
    section.add "X-Amz-Signature", valid_593967
  var valid_593968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593968 = validateParameter(valid_593968, JString, required = false,
                                 default = nil)
  if valid_593968 != nil:
    section.add "X-Amz-Content-Sha256", valid_593968
  var valid_593969 = header.getOrDefault("X-Amz-Date")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "X-Amz-Date", valid_593969
  var valid_593970 = header.getOrDefault("X-Amz-Credential")
  valid_593970 = validateParameter(valid_593970, JString, required = false,
                                 default = nil)
  if valid_593970 != nil:
    section.add "X-Amz-Credential", valid_593970
  var valid_593971 = header.getOrDefault("X-Amz-Security-Token")
  valid_593971 = validateParameter(valid_593971, JString, required = false,
                                 default = nil)
  if valid_593971 != nil:
    section.add "X-Amz-Security-Token", valid_593971
  var valid_593972 = header.getOrDefault("X-Amz-Algorithm")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "X-Amz-Algorithm", valid_593972
  var valid_593973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-SignedHeaders", valid_593973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593975: Call_GetMapping_593963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_593975.validator(path, query, header, formData, body)
  let scheme = call_593975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593975.url(scheme.get, call_593975.host, call_593975.base,
                         call_593975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593975, url, valid)

proc call*(call_593976: Call_GetMapping_593963; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_593977 = newJObject()
  if body != nil:
    body_593977 = body
  result = call_593976.call(nil, nil, nil, nil, body_593977)

var getMapping* = Call_GetMapping_593963(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_593964,
                                      base: "/", url: url_GetMapping_593965,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_593978 = ref object of OpenApiRestCall_592364
proc url_GetPartition_593980(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartition_593979(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593981 = header.getOrDefault("X-Amz-Target")
  valid_593981 = validateParameter(valid_593981, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_593981 != nil:
    section.add "X-Amz-Target", valid_593981
  var valid_593982 = header.getOrDefault("X-Amz-Signature")
  valid_593982 = validateParameter(valid_593982, JString, required = false,
                                 default = nil)
  if valid_593982 != nil:
    section.add "X-Amz-Signature", valid_593982
  var valid_593983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "X-Amz-Content-Sha256", valid_593983
  var valid_593984 = header.getOrDefault("X-Amz-Date")
  valid_593984 = validateParameter(valid_593984, JString, required = false,
                                 default = nil)
  if valid_593984 != nil:
    section.add "X-Amz-Date", valid_593984
  var valid_593985 = header.getOrDefault("X-Amz-Credential")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "X-Amz-Credential", valid_593985
  var valid_593986 = header.getOrDefault("X-Amz-Security-Token")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "X-Amz-Security-Token", valid_593986
  var valid_593987 = header.getOrDefault("X-Amz-Algorithm")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "X-Amz-Algorithm", valid_593987
  var valid_593988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-SignedHeaders", valid_593988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593990: Call_GetPartition_593978; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_593990.validator(path, query, header, formData, body)
  let scheme = call_593990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593990.url(scheme.get, call_593990.host, call_593990.base,
                         call_593990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593990, url, valid)

proc call*(call_593991: Call_GetPartition_593978; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_593992 = newJObject()
  if body != nil:
    body_593992 = body
  result = call_593991.call(nil, nil, nil, nil, body_593992)

var getPartition* = Call_GetPartition_593978(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_593979, base: "/", url: url_GetPartition_593980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_593993 = ref object of OpenApiRestCall_592364
proc url_GetPartitions_593995(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPartitions_593994(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593996 = query.getOrDefault("MaxResults")
  valid_593996 = validateParameter(valid_593996, JString, required = false,
                                 default = nil)
  if valid_593996 != nil:
    section.add "MaxResults", valid_593996
  var valid_593997 = query.getOrDefault("NextToken")
  valid_593997 = validateParameter(valid_593997, JString, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "NextToken", valid_593997
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
  var valid_593998 = header.getOrDefault("X-Amz-Target")
  valid_593998 = validateParameter(valid_593998, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_593998 != nil:
    section.add "X-Amz-Target", valid_593998
  var valid_593999 = header.getOrDefault("X-Amz-Signature")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-Signature", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Content-Sha256", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Date")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Date", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Credential")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Credential", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Security-Token")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Security-Token", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Algorithm")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Algorithm", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-SignedHeaders", valid_594005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594007: Call_GetPartitions_593993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_594007.validator(path, query, header, formData, body)
  let scheme = call_594007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594007.url(scheme.get, call_594007.host, call_594007.base,
                         call_594007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594007, url, valid)

proc call*(call_594008: Call_GetPartitions_593993; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594009 = newJObject()
  var body_594010 = newJObject()
  add(query_594009, "MaxResults", newJString(MaxResults))
  add(query_594009, "NextToken", newJString(NextToken))
  if body != nil:
    body_594010 = body
  result = call_594008.call(nil, query_594009, nil, nil, body_594010)

var getPartitions* = Call_GetPartitions_593993(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_593994, base: "/", url: url_GetPartitions_593995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_594011 = ref object of OpenApiRestCall_592364
proc url_GetPlan_594013(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPlan_594012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594014 = header.getOrDefault("X-Amz-Target")
  valid_594014 = validateParameter(valid_594014, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_594014 != nil:
    section.add "X-Amz-Target", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Signature")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Signature", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Content-Sha256", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Date")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Date", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Credential")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Credential", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Security-Token")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Security-Token", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Algorithm")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Algorithm", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-SignedHeaders", valid_594021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594023: Call_GetPlan_594011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_594023.validator(path, query, header, formData, body)
  let scheme = call_594023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594023.url(scheme.get, call_594023.host, call_594023.base,
                         call_594023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594023, url, valid)

proc call*(call_594024: Call_GetPlan_594011; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_594025 = newJObject()
  if body != nil:
    body_594025 = body
  result = call_594024.call(nil, nil, nil, nil, body_594025)

var getPlan* = Call_GetPlan_594011(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_594012, base: "/",
                                url: url_GetPlan_594013,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_594026 = ref object of OpenApiRestCall_592364
proc url_GetResourcePolicy_594028(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourcePolicy_594027(path: JsonNode; query: JsonNode;
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
  var valid_594029 = header.getOrDefault("X-Amz-Target")
  valid_594029 = validateParameter(valid_594029, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_594029 != nil:
    section.add "X-Amz-Target", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Signature")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Signature", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Content-Sha256", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Date")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Date", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Credential")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Credential", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Security-Token")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Security-Token", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Algorithm")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Algorithm", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-SignedHeaders", valid_594036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594038: Call_GetResourcePolicy_594026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_GetResourcePolicy_594026; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_594040 = newJObject()
  if body != nil:
    body_594040 = body
  result = call_594039.call(nil, nil, nil, nil, body_594040)

var getResourcePolicy* = Call_GetResourcePolicy_594026(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_594027, base: "/",
    url: url_GetResourcePolicy_594028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_594041 = ref object of OpenApiRestCall_592364
proc url_GetSecurityConfiguration_594043(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfiguration_594042(path: JsonNode; query: JsonNode;
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
  var valid_594044 = header.getOrDefault("X-Amz-Target")
  valid_594044 = validateParameter(valid_594044, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_594044 != nil:
    section.add "X-Amz-Target", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Signature")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Signature", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Content-Sha256", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Credential")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Credential", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-SignedHeaders", valid_594051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594053: Call_GetSecurityConfiguration_594041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_GetSecurityConfiguration_594041; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_594055 = newJObject()
  if body != nil:
    body_594055 = body
  result = call_594054.call(nil, nil, nil, nil, body_594055)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_594041(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_594042, base: "/",
    url: url_GetSecurityConfiguration_594043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_594056 = ref object of OpenApiRestCall_592364
proc url_GetSecurityConfigurations_594058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSecurityConfigurations_594057(path: JsonNode; query: JsonNode;
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
  var valid_594059 = query.getOrDefault("MaxResults")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "MaxResults", valid_594059
  var valid_594060 = query.getOrDefault("NextToken")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "NextToken", valid_594060
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
  var valid_594061 = header.getOrDefault("X-Amz-Target")
  valid_594061 = validateParameter(valid_594061, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_594061 != nil:
    section.add "X-Amz-Target", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Signature")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Signature", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Content-Sha256", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Date")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Date", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Credential")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Credential", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Security-Token")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Security-Token", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Algorithm")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Algorithm", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-SignedHeaders", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_GetSecurityConfigurations_594056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_GetSecurityConfigurations_594056; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594072 = newJObject()
  var body_594073 = newJObject()
  add(query_594072, "MaxResults", newJString(MaxResults))
  add(query_594072, "NextToken", newJString(NextToken))
  if body != nil:
    body_594073 = body
  result = call_594071.call(nil, query_594072, nil, nil, body_594073)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_594056(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_594057, base: "/",
    url: url_GetSecurityConfigurations_594058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_594074 = ref object of OpenApiRestCall_592364
proc url_GetTable_594076(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTable_594075(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594077 = header.getOrDefault("X-Amz-Target")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_594077 != nil:
    section.add "X-Amz-Target", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Signature")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Signature", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Date")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Date", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Credential")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Credential", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Security-Token")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Security-Token", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Algorithm")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Algorithm", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-SignedHeaders", valid_594084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_GetTable_594074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_GetTable_594074; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_594088 = newJObject()
  if body != nil:
    body_594088 = body
  result = call_594087.call(nil, nil, nil, nil, body_594088)

var getTable* = Call_GetTable_594074(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_594075, base: "/",
                                  url: url_GetTable_594076,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_594089 = ref object of OpenApiRestCall_592364
proc url_GetTableVersion_594091(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersion_594090(path: JsonNode; query: JsonNode;
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
  var valid_594092 = header.getOrDefault("X-Amz-Target")
  valid_594092 = validateParameter(valid_594092, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_594092 != nil:
    section.add "X-Amz-Target", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Signature")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Signature", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Date")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Date", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Credential")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Credential", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Security-Token")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Security-Token", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Algorithm")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Algorithm", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-SignedHeaders", valid_594099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594101: Call_GetTableVersion_594089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_594101.validator(path, query, header, formData, body)
  let scheme = call_594101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594101.url(scheme.get, call_594101.host, call_594101.base,
                         call_594101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594101, url, valid)

proc call*(call_594102: Call_GetTableVersion_594089; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_594103 = newJObject()
  if body != nil:
    body_594103 = body
  result = call_594102.call(nil, nil, nil, nil, body_594103)

var getTableVersion* = Call_GetTableVersion_594089(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_594090, base: "/", url: url_GetTableVersion_594091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_594104 = ref object of OpenApiRestCall_592364
proc url_GetTableVersions_594106(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTableVersions_594105(path: JsonNode; query: JsonNode;
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
  var valid_594107 = query.getOrDefault("MaxResults")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "MaxResults", valid_594107
  var valid_594108 = query.getOrDefault("NextToken")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "NextToken", valid_594108
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
  var valid_594109 = header.getOrDefault("X-Amz-Target")
  valid_594109 = validateParameter(valid_594109, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_594109 != nil:
    section.add "X-Amz-Target", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Signature")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Signature", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Date")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Date", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Security-Token")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Security-Token", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Algorithm")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Algorithm", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-SignedHeaders", valid_594116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594118: Call_GetTableVersions_594104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_594118.validator(path, query, header, formData, body)
  let scheme = call_594118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594118.url(scheme.get, call_594118.host, call_594118.base,
                         call_594118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594118, url, valid)

proc call*(call_594119: Call_GetTableVersions_594104; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594120 = newJObject()
  var body_594121 = newJObject()
  add(query_594120, "MaxResults", newJString(MaxResults))
  add(query_594120, "NextToken", newJString(NextToken))
  if body != nil:
    body_594121 = body
  result = call_594119.call(nil, query_594120, nil, nil, body_594121)

var getTableVersions* = Call_GetTableVersions_594104(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_594105, base: "/",
    url: url_GetTableVersions_594106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_594122 = ref object of OpenApiRestCall_592364
proc url_GetTables_594124(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTables_594123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594125 = query.getOrDefault("MaxResults")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "MaxResults", valid_594125
  var valid_594126 = query.getOrDefault("NextToken")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "NextToken", valid_594126
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
  var valid_594127 = header.getOrDefault("X-Amz-Target")
  valid_594127 = validateParameter(valid_594127, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_594127 != nil:
    section.add "X-Amz-Target", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Signature")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Signature", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Content-Sha256", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Credential")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Credential", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Security-Token")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Security-Token", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-SignedHeaders", valid_594134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594136: Call_GetTables_594122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_594136.validator(path, query, header, formData, body)
  let scheme = call_594136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594136.url(scheme.get, call_594136.host, call_594136.base,
                         call_594136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594136, url, valid)

proc call*(call_594137: Call_GetTables_594122; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594138 = newJObject()
  var body_594139 = newJObject()
  add(query_594138, "MaxResults", newJString(MaxResults))
  add(query_594138, "NextToken", newJString(NextToken))
  if body != nil:
    body_594139 = body
  result = call_594137.call(nil, query_594138, nil, nil, body_594139)

var getTables* = Call_GetTables_594122(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_594123,
                                    base: "/", url: url_GetTables_594124,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_594140 = ref object of OpenApiRestCall_592364
proc url_GetTags_594142(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTags_594141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594143 = header.getOrDefault("X-Amz-Target")
  valid_594143 = validateParameter(valid_594143, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_594143 != nil:
    section.add "X-Amz-Target", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Signature")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Signature", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Date")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Date", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Credential")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Credential", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Security-Token")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Security-Token", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Algorithm")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Algorithm", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-SignedHeaders", valid_594150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594152: Call_GetTags_594140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_594152.validator(path, query, header, formData, body)
  let scheme = call_594152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594152.url(scheme.get, call_594152.host, call_594152.base,
                         call_594152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594152, url, valid)

proc call*(call_594153: Call_GetTags_594140; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_594154 = newJObject()
  if body != nil:
    body_594154 = body
  result = call_594153.call(nil, nil, nil, nil, body_594154)

var getTags* = Call_GetTags_594140(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_594141, base: "/",
                                url: url_GetTags_594142,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_594155 = ref object of OpenApiRestCall_592364
proc url_GetTrigger_594157(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTrigger_594156(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594158 = header.getOrDefault("X-Amz-Target")
  valid_594158 = validateParameter(valid_594158, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_594158 != nil:
    section.add "X-Amz-Target", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Signature")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Signature", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Content-Sha256", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Date")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Date", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Credential")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Credential", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Security-Token")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Security-Token", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Algorithm")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Algorithm", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-SignedHeaders", valid_594165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594167: Call_GetTrigger_594155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_594167.validator(path, query, header, formData, body)
  let scheme = call_594167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594167.url(scheme.get, call_594167.host, call_594167.base,
                         call_594167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594167, url, valid)

proc call*(call_594168: Call_GetTrigger_594155; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_594169 = newJObject()
  if body != nil:
    body_594169 = body
  result = call_594168.call(nil, nil, nil, nil, body_594169)

var getTrigger* = Call_GetTrigger_594155(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_594156,
                                      base: "/", url: url_GetTrigger_594157,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_594170 = ref object of OpenApiRestCall_592364
proc url_GetTriggers_594172(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTriggers_594171(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594173 = query.getOrDefault("MaxResults")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "MaxResults", valid_594173
  var valid_594174 = query.getOrDefault("NextToken")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "NextToken", valid_594174
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
  var valid_594175 = header.getOrDefault("X-Amz-Target")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_594175 != nil:
    section.add "X-Amz-Target", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Signature")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Signature", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Content-Sha256", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Date")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Date", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Credential")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Credential", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Security-Token")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Security-Token", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Algorithm")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Algorithm", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-SignedHeaders", valid_594182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594184: Call_GetTriggers_594170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_594184.validator(path, query, header, formData, body)
  let scheme = call_594184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594184.url(scheme.get, call_594184.host, call_594184.base,
                         call_594184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594184, url, valid)

proc call*(call_594185: Call_GetTriggers_594170; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594186 = newJObject()
  var body_594187 = newJObject()
  add(query_594186, "MaxResults", newJString(MaxResults))
  add(query_594186, "NextToken", newJString(NextToken))
  if body != nil:
    body_594187 = body
  result = call_594185.call(nil, query_594186, nil, nil, body_594187)

var getTriggers* = Call_GetTriggers_594170(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_594171,
                                        base: "/", url: url_GetTriggers_594172,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_594188 = ref object of OpenApiRestCall_592364
proc url_GetUserDefinedFunction_594190(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunction_594189(path: JsonNode; query: JsonNode;
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
  var valid_594191 = header.getOrDefault("X-Amz-Target")
  valid_594191 = validateParameter(valid_594191, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_594191 != nil:
    section.add "X-Amz-Target", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Signature")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Signature", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Content-Sha256", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Date")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Date", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Credential")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Credential", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Security-Token")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Security-Token", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Algorithm")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Algorithm", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-SignedHeaders", valid_594198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594200: Call_GetUserDefinedFunction_594188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_594200.validator(path, query, header, formData, body)
  let scheme = call_594200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594200.url(scheme.get, call_594200.host, call_594200.base,
                         call_594200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594200, url, valid)

proc call*(call_594201: Call_GetUserDefinedFunction_594188; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_594202 = newJObject()
  if body != nil:
    body_594202 = body
  result = call_594201.call(nil, nil, nil, nil, body_594202)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_594188(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_594189, base: "/",
    url: url_GetUserDefinedFunction_594190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_594203 = ref object of OpenApiRestCall_592364
proc url_GetUserDefinedFunctions_594205(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUserDefinedFunctions_594204(path: JsonNode; query: JsonNode;
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
  var valid_594206 = query.getOrDefault("MaxResults")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "MaxResults", valid_594206
  var valid_594207 = query.getOrDefault("NextToken")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "NextToken", valid_594207
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
  var valid_594208 = header.getOrDefault("X-Amz-Target")
  valid_594208 = validateParameter(valid_594208, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_594208 != nil:
    section.add "X-Amz-Target", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Signature")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Signature", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Content-Sha256", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Credential")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Credential", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Security-Token")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Security-Token", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Algorithm")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Algorithm", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-SignedHeaders", valid_594215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594217: Call_GetUserDefinedFunctions_594203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_594217.validator(path, query, header, formData, body)
  let scheme = call_594217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594217.url(scheme.get, call_594217.host, call_594217.base,
                         call_594217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594217, url, valid)

proc call*(call_594218: Call_GetUserDefinedFunctions_594203; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594219 = newJObject()
  var body_594220 = newJObject()
  add(query_594219, "MaxResults", newJString(MaxResults))
  add(query_594219, "NextToken", newJString(NextToken))
  if body != nil:
    body_594220 = body
  result = call_594218.call(nil, query_594219, nil, nil, body_594220)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_594203(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_594204, base: "/",
    url: url_GetUserDefinedFunctions_594205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_594221 = ref object of OpenApiRestCall_592364
proc url_GetWorkflow_594223(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflow_594222(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594224 = header.getOrDefault("X-Amz-Target")
  valid_594224 = validateParameter(valid_594224, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_594224 != nil:
    section.add "X-Amz-Target", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Signature")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Signature", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Date")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Date", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Security-Token")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Security-Token", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-SignedHeaders", valid_594231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594233: Call_GetWorkflow_594221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_594233.validator(path, query, header, formData, body)
  let scheme = call_594233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594233.url(scheme.get, call_594233.host, call_594233.base,
                         call_594233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594233, url, valid)

proc call*(call_594234: Call_GetWorkflow_594221; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_594235 = newJObject()
  if body != nil:
    body_594235 = body
  result = call_594234.call(nil, nil, nil, nil, body_594235)

var getWorkflow* = Call_GetWorkflow_594221(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_594222,
                                        base: "/", url: url_GetWorkflow_594223,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_594236 = ref object of OpenApiRestCall_592364
proc url_GetWorkflowRun_594238(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRun_594237(path: JsonNode; query: JsonNode;
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
  var valid_594239 = header.getOrDefault("X-Amz-Target")
  valid_594239 = validateParameter(valid_594239, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_594239 != nil:
    section.add "X-Amz-Target", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Content-Sha256", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Date")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Date", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Credential")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Credential", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-SignedHeaders", valid_594246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594248: Call_GetWorkflowRun_594236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_594248.validator(path, query, header, formData, body)
  let scheme = call_594248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594248.url(scheme.get, call_594248.host, call_594248.base,
                         call_594248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594248, url, valid)

proc call*(call_594249: Call_GetWorkflowRun_594236; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_594250 = newJObject()
  if body != nil:
    body_594250 = body
  result = call_594249.call(nil, nil, nil, nil, body_594250)

var getWorkflowRun* = Call_GetWorkflowRun_594236(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_594237, base: "/", url: url_GetWorkflowRun_594238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_594251 = ref object of OpenApiRestCall_592364
proc url_GetWorkflowRunProperties_594253(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRunProperties_594252(path: JsonNode; query: JsonNode;
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
  var valid_594254 = header.getOrDefault("X-Amz-Target")
  valid_594254 = validateParameter(valid_594254, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_594254 != nil:
    section.add "X-Amz-Target", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Signature")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Signature", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Date")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Date", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Credential")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Credential", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Security-Token")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Security-Token", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-SignedHeaders", valid_594261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_GetWorkflowRunProperties_594251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_GetWorkflowRunProperties_594251; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_594265 = newJObject()
  if body != nil:
    body_594265 = body
  result = call_594264.call(nil, nil, nil, nil, body_594265)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_594251(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_594252, base: "/",
    url: url_GetWorkflowRunProperties_594253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_594266 = ref object of OpenApiRestCall_592364
proc url_GetWorkflowRuns_594268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowRuns_594267(path: JsonNode; query: JsonNode;
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
  var valid_594269 = query.getOrDefault("MaxResults")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "MaxResults", valid_594269
  var valid_594270 = query.getOrDefault("NextToken")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "NextToken", valid_594270
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
  var valid_594271 = header.getOrDefault("X-Amz-Target")
  valid_594271 = validateParameter(valid_594271, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_594271 != nil:
    section.add "X-Amz-Target", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Signature")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Signature", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Content-Sha256", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Date")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Date", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Credential")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Credential", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Security-Token")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Security-Token", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Algorithm")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Algorithm", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-SignedHeaders", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_GetWorkflowRuns_594266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_GetWorkflowRuns_594266; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594282 = newJObject()
  var body_594283 = newJObject()
  add(query_594282, "MaxResults", newJString(MaxResults))
  add(query_594282, "NextToken", newJString(NextToken))
  if body != nil:
    body_594283 = body
  result = call_594281.call(nil, query_594282, nil, nil, body_594283)

var getWorkflowRuns* = Call_GetWorkflowRuns_594266(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_594267, base: "/", url: url_GetWorkflowRuns_594268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_594284 = ref object of OpenApiRestCall_592364
proc url_ImportCatalogToGlue_594286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportCatalogToGlue_594285(path: JsonNode; query: JsonNode;
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
  var valid_594287 = header.getOrDefault("X-Amz-Target")
  valid_594287 = validateParameter(valid_594287, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_594287 != nil:
    section.add "X-Amz-Target", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Signature")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Signature", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Date")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Date", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Credential")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Credential", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Security-Token")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Security-Token", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Algorithm")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Algorithm", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-SignedHeaders", valid_594294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594296: Call_ImportCatalogToGlue_594284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_594296.validator(path, query, header, formData, body)
  let scheme = call_594296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594296.url(scheme.get, call_594296.host, call_594296.base,
                         call_594296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594296, url, valid)

proc call*(call_594297: Call_ImportCatalogToGlue_594284; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_594298 = newJObject()
  if body != nil:
    body_594298 = body
  result = call_594297.call(nil, nil, nil, nil, body_594298)

var importCatalogToGlue* = Call_ImportCatalogToGlue_594284(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_594285, base: "/",
    url: url_ImportCatalogToGlue_594286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_594299 = ref object of OpenApiRestCall_592364
proc url_ListCrawlers_594301(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCrawlers_594300(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594302 = query.getOrDefault("MaxResults")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "MaxResults", valid_594302
  var valid_594303 = query.getOrDefault("NextToken")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "NextToken", valid_594303
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
  var valid_594304 = header.getOrDefault("X-Amz-Target")
  valid_594304 = validateParameter(valid_594304, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_594304 != nil:
    section.add "X-Amz-Target", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Signature")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Signature", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Content-Sha256", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Date")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Date", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Security-Token")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Security-Token", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Algorithm")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Algorithm", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-SignedHeaders", valid_594311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594313: Call_ListCrawlers_594299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_594313.validator(path, query, header, formData, body)
  let scheme = call_594313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594313.url(scheme.get, call_594313.host, call_594313.base,
                         call_594313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594313, url, valid)

proc call*(call_594314: Call_ListCrawlers_594299; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594315 = newJObject()
  var body_594316 = newJObject()
  add(query_594315, "MaxResults", newJString(MaxResults))
  add(query_594315, "NextToken", newJString(NextToken))
  if body != nil:
    body_594316 = body
  result = call_594314.call(nil, query_594315, nil, nil, body_594316)

var listCrawlers* = Call_ListCrawlers_594299(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_594300, base: "/", url: url_ListCrawlers_594301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_594317 = ref object of OpenApiRestCall_592364
proc url_ListDevEndpoints_594319(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevEndpoints_594318(path: JsonNode; query: JsonNode;
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
  var valid_594320 = query.getOrDefault("MaxResults")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "MaxResults", valid_594320
  var valid_594321 = query.getOrDefault("NextToken")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "NextToken", valid_594321
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
  var valid_594322 = header.getOrDefault("X-Amz-Target")
  valid_594322 = validateParameter(valid_594322, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_594322 != nil:
    section.add "X-Amz-Target", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Signature")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Signature", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Content-Sha256", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Date")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Date", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Credential")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Credential", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Security-Token")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Security-Token", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Algorithm")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Algorithm", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-SignedHeaders", valid_594329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594331: Call_ListDevEndpoints_594317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_594331.validator(path, query, header, formData, body)
  let scheme = call_594331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594331.url(scheme.get, call_594331.host, call_594331.base,
                         call_594331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594331, url, valid)

proc call*(call_594332: Call_ListDevEndpoints_594317; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594333 = newJObject()
  var body_594334 = newJObject()
  add(query_594333, "MaxResults", newJString(MaxResults))
  add(query_594333, "NextToken", newJString(NextToken))
  if body != nil:
    body_594334 = body
  result = call_594332.call(nil, query_594333, nil, nil, body_594334)

var listDevEndpoints* = Call_ListDevEndpoints_594317(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_594318, base: "/",
    url: url_ListDevEndpoints_594319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_594335 = ref object of OpenApiRestCall_592364
proc url_ListJobs_594337(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_594336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594338 = query.getOrDefault("MaxResults")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "MaxResults", valid_594338
  var valid_594339 = query.getOrDefault("NextToken")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "NextToken", valid_594339
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
  var valid_594340 = header.getOrDefault("X-Amz-Target")
  valid_594340 = validateParameter(valid_594340, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_594340 != nil:
    section.add "X-Amz-Target", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Signature")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Signature", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Content-Sha256", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Date")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Date", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Credential")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Credential", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Security-Token")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Security-Token", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Algorithm")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Algorithm", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-SignedHeaders", valid_594347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594349: Call_ListJobs_594335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_594349.validator(path, query, header, formData, body)
  let scheme = call_594349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594349.url(scheme.get, call_594349.host, call_594349.base,
                         call_594349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594349, url, valid)

proc call*(call_594350: Call_ListJobs_594335; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594351 = newJObject()
  var body_594352 = newJObject()
  add(query_594351, "MaxResults", newJString(MaxResults))
  add(query_594351, "NextToken", newJString(NextToken))
  if body != nil:
    body_594352 = body
  result = call_594350.call(nil, query_594351, nil, nil, body_594352)

var listJobs* = Call_ListJobs_594335(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_594336, base: "/",
                                  url: url_ListJobs_594337,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_594353 = ref object of OpenApiRestCall_592364
proc url_ListTriggers_594355(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTriggers_594354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594356 = query.getOrDefault("MaxResults")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "MaxResults", valid_594356
  var valid_594357 = query.getOrDefault("NextToken")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "NextToken", valid_594357
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
  var valid_594358 = header.getOrDefault("X-Amz-Target")
  valid_594358 = validateParameter(valid_594358, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_594358 != nil:
    section.add "X-Amz-Target", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Signature")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Signature", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Content-Sha256", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Credential")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Credential", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Security-Token")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Security-Token", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Algorithm")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Algorithm", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-SignedHeaders", valid_594365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594367: Call_ListTriggers_594353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_594367.validator(path, query, header, formData, body)
  let scheme = call_594367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594367.url(scheme.get, call_594367.host, call_594367.base,
                         call_594367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594367, url, valid)

proc call*(call_594368: Call_ListTriggers_594353; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594369 = newJObject()
  var body_594370 = newJObject()
  add(query_594369, "MaxResults", newJString(MaxResults))
  add(query_594369, "NextToken", newJString(NextToken))
  if body != nil:
    body_594370 = body
  result = call_594368.call(nil, query_594369, nil, nil, body_594370)

var listTriggers* = Call_ListTriggers_594353(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_594354, base: "/", url: url_ListTriggers_594355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_594371 = ref object of OpenApiRestCall_592364
proc url_ListWorkflows_594373(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkflows_594372(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594374 = query.getOrDefault("MaxResults")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "MaxResults", valid_594374
  var valid_594375 = query.getOrDefault("NextToken")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "NextToken", valid_594375
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
  var valid_594376 = header.getOrDefault("X-Amz-Target")
  valid_594376 = validateParameter(valid_594376, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_594376 != nil:
    section.add "X-Amz-Target", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Signature")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Signature", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Content-Sha256", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Date")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Date", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Credential")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Credential", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Security-Token")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Security-Token", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Algorithm")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Algorithm", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-SignedHeaders", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594385: Call_ListWorkflows_594371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_594385.validator(path, query, header, formData, body)
  let scheme = call_594385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594385.url(scheme.get, call_594385.host, call_594385.base,
                         call_594385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594385, url, valid)

proc call*(call_594386: Call_ListWorkflows_594371; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594387 = newJObject()
  var body_594388 = newJObject()
  add(query_594387, "MaxResults", newJString(MaxResults))
  add(query_594387, "NextToken", newJString(NextToken))
  if body != nil:
    body_594388 = body
  result = call_594386.call(nil, query_594387, nil, nil, body_594388)

var listWorkflows* = Call_ListWorkflows_594371(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_594372, base: "/", url: url_ListWorkflows_594373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_594389 = ref object of OpenApiRestCall_592364
proc url_PutDataCatalogEncryptionSettings_594391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDataCatalogEncryptionSettings_594390(path: JsonNode;
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
  var valid_594392 = header.getOrDefault("X-Amz-Target")
  valid_594392 = validateParameter(valid_594392, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_594392 != nil:
    section.add "X-Amz-Target", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Signature")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Signature", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Content-Sha256", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Date")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Date", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Credential")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Credential", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Security-Token")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Security-Token", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Algorithm")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Algorithm", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-SignedHeaders", valid_594399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594401: Call_PutDataCatalogEncryptionSettings_594389;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_594401.validator(path, query, header, formData, body)
  let scheme = call_594401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594401.url(scheme.get, call_594401.host, call_594401.base,
                         call_594401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594401, url, valid)

proc call*(call_594402: Call_PutDataCatalogEncryptionSettings_594389;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_594403 = newJObject()
  if body != nil:
    body_594403 = body
  result = call_594402.call(nil, nil, nil, nil, body_594403)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_594389(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_594390, base: "/",
    url: url_PutDataCatalogEncryptionSettings_594391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_594404 = ref object of OpenApiRestCall_592364
proc url_PutResourcePolicy_594406(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutResourcePolicy_594405(path: JsonNode; query: JsonNode;
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
  var valid_594407 = header.getOrDefault("X-Amz-Target")
  valid_594407 = validateParameter(valid_594407, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_594407 != nil:
    section.add "X-Amz-Target", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Signature")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Signature", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Content-Sha256", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Date")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Date", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Credential")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Credential", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Security-Token")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Security-Token", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Algorithm")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Algorithm", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-SignedHeaders", valid_594414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594416: Call_PutResourcePolicy_594404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_594416.validator(path, query, header, formData, body)
  let scheme = call_594416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594416.url(scheme.get, call_594416.host, call_594416.base,
                         call_594416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594416, url, valid)

proc call*(call_594417: Call_PutResourcePolicy_594404; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_594418 = newJObject()
  if body != nil:
    body_594418 = body
  result = call_594417.call(nil, nil, nil, nil, body_594418)

var putResourcePolicy* = Call_PutResourcePolicy_594404(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_594405, base: "/",
    url: url_PutResourcePolicy_594406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_594419 = ref object of OpenApiRestCall_592364
proc url_PutWorkflowRunProperties_594421(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutWorkflowRunProperties_594420(path: JsonNode; query: JsonNode;
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
  var valid_594422 = header.getOrDefault("X-Amz-Target")
  valid_594422 = validateParameter(valid_594422, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_594422 != nil:
    section.add "X-Amz-Target", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Signature")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Signature", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Content-Sha256", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Credential")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Credential", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Security-Token")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Security-Token", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Algorithm")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Algorithm", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-SignedHeaders", valid_594429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594431: Call_PutWorkflowRunProperties_594419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_594431.validator(path, query, header, formData, body)
  let scheme = call_594431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594431.url(scheme.get, call_594431.host, call_594431.base,
                         call_594431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594431, url, valid)

proc call*(call_594432: Call_PutWorkflowRunProperties_594419; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_594433 = newJObject()
  if body != nil:
    body_594433 = body
  result = call_594432.call(nil, nil, nil, nil, body_594433)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_594419(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_594420, base: "/",
    url: url_PutWorkflowRunProperties_594421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_594434 = ref object of OpenApiRestCall_592364
proc url_ResetJobBookmark_594436(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetJobBookmark_594435(path: JsonNode; query: JsonNode;
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
  var valid_594437 = header.getOrDefault("X-Amz-Target")
  valid_594437 = validateParameter(valid_594437, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_594437 != nil:
    section.add "X-Amz-Target", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Signature")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Signature", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Content-Sha256", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Date")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Date", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Credential")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Credential", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Security-Token")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Security-Token", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Algorithm")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Algorithm", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-SignedHeaders", valid_594444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594446: Call_ResetJobBookmark_594434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_594446.validator(path, query, header, formData, body)
  let scheme = call_594446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594446.url(scheme.get, call_594446.host, call_594446.base,
                         call_594446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594446, url, valid)

proc call*(call_594447: Call_ResetJobBookmark_594434; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_594448 = newJObject()
  if body != nil:
    body_594448 = body
  result = call_594447.call(nil, nil, nil, nil, body_594448)

var resetJobBookmark* = Call_ResetJobBookmark_594434(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_594435, base: "/",
    url: url_ResetJobBookmark_594436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_594449 = ref object of OpenApiRestCall_592364
proc url_SearchTables_594451(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchTables_594450(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594452 = query.getOrDefault("MaxResults")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "MaxResults", valid_594452
  var valid_594453 = query.getOrDefault("NextToken")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "NextToken", valid_594453
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
  var valid_594454 = header.getOrDefault("X-Amz-Target")
  valid_594454 = validateParameter(valid_594454, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_594454 != nil:
    section.add "X-Amz-Target", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Signature")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Signature", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Content-Sha256", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Date")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Date", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Credential")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Credential", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Security-Token")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Security-Token", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Algorithm")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Algorithm", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-SignedHeaders", valid_594461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594463: Call_SearchTables_594449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_594463.validator(path, query, header, formData, body)
  let scheme = call_594463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594463.url(scheme.get, call_594463.host, call_594463.base,
                         call_594463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594463, url, valid)

proc call*(call_594464: Call_SearchTables_594449; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594465 = newJObject()
  var body_594466 = newJObject()
  add(query_594465, "MaxResults", newJString(MaxResults))
  add(query_594465, "NextToken", newJString(NextToken))
  if body != nil:
    body_594466 = body
  result = call_594464.call(nil, query_594465, nil, nil, body_594466)

var searchTables* = Call_SearchTables_594449(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_594450, base: "/", url: url_SearchTables_594451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_594467 = ref object of OpenApiRestCall_592364
proc url_StartCrawler_594469(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawler_594468(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594470 = header.getOrDefault("X-Amz-Target")
  valid_594470 = validateParameter(valid_594470, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_594470 != nil:
    section.add "X-Amz-Target", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Signature")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Signature", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Content-Sha256", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Date")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Date", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Credential")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Credential", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Security-Token")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Security-Token", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Algorithm")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Algorithm", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-SignedHeaders", valid_594477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594479: Call_StartCrawler_594467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_594479.validator(path, query, header, formData, body)
  let scheme = call_594479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594479.url(scheme.get, call_594479.host, call_594479.base,
                         call_594479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594479, url, valid)

proc call*(call_594480: Call_StartCrawler_594467; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_594481 = newJObject()
  if body != nil:
    body_594481 = body
  result = call_594480.call(nil, nil, nil, nil, body_594481)

var startCrawler* = Call_StartCrawler_594467(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_594468, base: "/", url: url_StartCrawler_594469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_594482 = ref object of OpenApiRestCall_592364
proc url_StartCrawlerSchedule_594484(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartCrawlerSchedule_594483(path: JsonNode; query: JsonNode;
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
  var valid_594485 = header.getOrDefault("X-Amz-Target")
  valid_594485 = validateParameter(valid_594485, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_594485 != nil:
    section.add "X-Amz-Target", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Signature")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Signature", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Content-Sha256", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Date")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Date", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Credential")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Credential", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Security-Token")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Security-Token", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Algorithm")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Algorithm", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-SignedHeaders", valid_594492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594494: Call_StartCrawlerSchedule_594482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_594494.validator(path, query, header, formData, body)
  let scheme = call_594494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594494.url(scheme.get, call_594494.host, call_594494.base,
                         call_594494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594494, url, valid)

proc call*(call_594495: Call_StartCrawlerSchedule_594482; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_594496 = newJObject()
  if body != nil:
    body_594496 = body
  result = call_594495.call(nil, nil, nil, nil, body_594496)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_594482(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_594483, base: "/",
    url: url_StartCrawlerSchedule_594484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_594497 = ref object of OpenApiRestCall_592364
proc url_StartExportLabelsTaskRun_594499(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartExportLabelsTaskRun_594498(path: JsonNode; query: JsonNode;
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
  var valid_594500 = header.getOrDefault("X-Amz-Target")
  valid_594500 = validateParameter(valid_594500, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_594500 != nil:
    section.add "X-Amz-Target", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Signature")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Signature", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Content-Sha256", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Date")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Date", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Credential")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Credential", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Security-Token")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Security-Token", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Algorithm")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Algorithm", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-SignedHeaders", valid_594507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594509: Call_StartExportLabelsTaskRun_594497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_594509.validator(path, query, header, formData, body)
  let scheme = call_594509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594509.url(scheme.get, call_594509.host, call_594509.base,
                         call_594509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594509, url, valid)

proc call*(call_594510: Call_StartExportLabelsTaskRun_594497; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_594511 = newJObject()
  if body != nil:
    body_594511 = body
  result = call_594510.call(nil, nil, nil, nil, body_594511)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_594497(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_594498, base: "/",
    url: url_StartExportLabelsTaskRun_594499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_594512 = ref object of OpenApiRestCall_592364
proc url_StartImportLabelsTaskRun_594514(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImportLabelsTaskRun_594513(path: JsonNode; query: JsonNode;
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
  var valid_594515 = header.getOrDefault("X-Amz-Target")
  valid_594515 = validateParameter(valid_594515, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_594515 != nil:
    section.add "X-Amz-Target", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Signature")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Signature", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Content-Sha256", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Date")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Date", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Credential")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Credential", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Security-Token")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Security-Token", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Algorithm")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Algorithm", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-SignedHeaders", valid_594522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594524: Call_StartImportLabelsTaskRun_594512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_594524.validator(path, query, header, formData, body)
  let scheme = call_594524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594524.url(scheme.get, call_594524.host, call_594524.base,
                         call_594524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594524, url, valid)

proc call*(call_594525: Call_StartImportLabelsTaskRun_594512; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_594526 = newJObject()
  if body != nil:
    body_594526 = body
  result = call_594525.call(nil, nil, nil, nil, body_594526)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_594512(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_594513, base: "/",
    url: url_StartImportLabelsTaskRun_594514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_594527 = ref object of OpenApiRestCall_592364
proc url_StartJobRun_594529(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartJobRun_594528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594530 = header.getOrDefault("X-Amz-Target")
  valid_594530 = validateParameter(valid_594530, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_594530 != nil:
    section.add "X-Amz-Target", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Content-Sha256", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Date")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Date", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Credential")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Credential", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Security-Token")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Security-Token", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Algorithm")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Algorithm", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-SignedHeaders", valid_594537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594539: Call_StartJobRun_594527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_594539.validator(path, query, header, formData, body)
  let scheme = call_594539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594539.url(scheme.get, call_594539.host, call_594539.base,
                         call_594539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594539, url, valid)

proc call*(call_594540: Call_StartJobRun_594527; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_594541 = newJObject()
  if body != nil:
    body_594541 = body
  result = call_594540.call(nil, nil, nil, nil, body_594541)

var startJobRun* = Call_StartJobRun_594527(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_594528,
                                        base: "/", url: url_StartJobRun_594529,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_594542 = ref object of OpenApiRestCall_592364
proc url_StartMLEvaluationTaskRun_594544(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLEvaluationTaskRun_594543(path: JsonNode; query: JsonNode;
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
  var valid_594545 = header.getOrDefault("X-Amz-Target")
  valid_594545 = validateParameter(valid_594545, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_594545 != nil:
    section.add "X-Amz-Target", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Signature")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Signature", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Content-Sha256", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Date")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Date", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Credential")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Credential", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Security-Token")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Security-Token", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Algorithm")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Algorithm", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-SignedHeaders", valid_594552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594554: Call_StartMLEvaluationTaskRun_594542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_594554.validator(path, query, header, formData, body)
  let scheme = call_594554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594554.url(scheme.get, call_594554.host, call_594554.base,
                         call_594554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594554, url, valid)

proc call*(call_594555: Call_StartMLEvaluationTaskRun_594542; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_594556 = newJObject()
  if body != nil:
    body_594556 = body
  result = call_594555.call(nil, nil, nil, nil, body_594556)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_594542(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_594543, base: "/",
    url: url_StartMLEvaluationTaskRun_594544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_594557 = ref object of OpenApiRestCall_592364
proc url_StartMLLabelingSetGenerationTaskRun_594559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMLLabelingSetGenerationTaskRun_594558(path: JsonNode;
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
  var valid_594560 = header.getOrDefault("X-Amz-Target")
  valid_594560 = validateParameter(valid_594560, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_594560 != nil:
    section.add "X-Amz-Target", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Signature")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Signature", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Content-Sha256", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Date")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Date", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Credential")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Credential", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Security-Token")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Security-Token", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Algorithm")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Algorithm", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-SignedHeaders", valid_594567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594569: Call_StartMLLabelingSetGenerationTaskRun_594557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_594569.validator(path, query, header, formData, body)
  let scheme = call_594569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594569.url(scheme.get, call_594569.host, call_594569.base,
                         call_594569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594569, url, valid)

proc call*(call_594570: Call_StartMLLabelingSetGenerationTaskRun_594557;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_594571 = newJObject()
  if body != nil:
    body_594571 = body
  result = call_594570.call(nil, nil, nil, nil, body_594571)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_594557(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_594558, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_594559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_594572 = ref object of OpenApiRestCall_592364
proc url_StartTrigger_594574(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTrigger_594573(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594575 = header.getOrDefault("X-Amz-Target")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_594575 != nil:
    section.add "X-Amz-Target", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Signature")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Signature", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Content-Sha256", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Date")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Date", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Credential")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Credential", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Security-Token")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Security-Token", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Algorithm")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Algorithm", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-SignedHeaders", valid_594582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594584: Call_StartTrigger_594572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_594584.validator(path, query, header, formData, body)
  let scheme = call_594584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594584.url(scheme.get, call_594584.host, call_594584.base,
                         call_594584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594584, url, valid)

proc call*(call_594585: Call_StartTrigger_594572; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_594586 = newJObject()
  if body != nil:
    body_594586 = body
  result = call_594585.call(nil, nil, nil, nil, body_594586)

var startTrigger* = Call_StartTrigger_594572(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_594573, base: "/", url: url_StartTrigger_594574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_594587 = ref object of OpenApiRestCall_592364
proc url_StartWorkflowRun_594589(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkflowRun_594588(path: JsonNode; query: JsonNode;
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
  var valid_594590 = header.getOrDefault("X-Amz-Target")
  valid_594590 = validateParameter(valid_594590, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_594590 != nil:
    section.add "X-Amz-Target", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Signature")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Signature", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Content-Sha256", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Date")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Date", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Credential")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Credential", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Security-Token")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Security-Token", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Algorithm")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Algorithm", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-SignedHeaders", valid_594597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594599: Call_StartWorkflowRun_594587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_594599.validator(path, query, header, formData, body)
  let scheme = call_594599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594599.url(scheme.get, call_594599.host, call_594599.base,
                         call_594599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594599, url, valid)

proc call*(call_594600: Call_StartWorkflowRun_594587; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_594601 = newJObject()
  if body != nil:
    body_594601 = body
  result = call_594600.call(nil, nil, nil, nil, body_594601)

var startWorkflowRun* = Call_StartWorkflowRun_594587(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_594588, base: "/",
    url: url_StartWorkflowRun_594589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_594602 = ref object of OpenApiRestCall_592364
proc url_StopCrawler_594604(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawler_594603(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594605 = header.getOrDefault("X-Amz-Target")
  valid_594605 = validateParameter(valid_594605, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_594605 != nil:
    section.add "X-Amz-Target", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Content-Sha256", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Date")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Date", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Credential")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Credential", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Security-Token")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Security-Token", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Algorithm")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Algorithm", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-SignedHeaders", valid_594612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594614: Call_StopCrawler_594602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_594614.validator(path, query, header, formData, body)
  let scheme = call_594614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594614.url(scheme.get, call_594614.host, call_594614.base,
                         call_594614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594614, url, valid)

proc call*(call_594615: Call_StopCrawler_594602; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_594616 = newJObject()
  if body != nil:
    body_594616 = body
  result = call_594615.call(nil, nil, nil, nil, body_594616)

var stopCrawler* = Call_StopCrawler_594602(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_594603,
                                        base: "/", url: url_StopCrawler_594604,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_594617 = ref object of OpenApiRestCall_592364
proc url_StopCrawlerSchedule_594619(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCrawlerSchedule_594618(path: JsonNode; query: JsonNode;
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
  var valid_594620 = header.getOrDefault("X-Amz-Target")
  valid_594620 = validateParameter(valid_594620, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_594620 != nil:
    section.add "X-Amz-Target", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Signature")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Signature", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Content-Sha256", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Date")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Date", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Credential")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Credential", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Security-Token")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Security-Token", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Algorithm")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Algorithm", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-SignedHeaders", valid_594627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594629: Call_StopCrawlerSchedule_594617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_594629.validator(path, query, header, formData, body)
  let scheme = call_594629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594629.url(scheme.get, call_594629.host, call_594629.base,
                         call_594629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594629, url, valid)

proc call*(call_594630: Call_StopCrawlerSchedule_594617; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_594631 = newJObject()
  if body != nil:
    body_594631 = body
  result = call_594630.call(nil, nil, nil, nil, body_594631)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_594617(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_594618, base: "/",
    url: url_StopCrawlerSchedule_594619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_594632 = ref object of OpenApiRestCall_592364
proc url_StopTrigger_594634(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrigger_594633(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594635 = header.getOrDefault("X-Amz-Target")
  valid_594635 = validateParameter(valid_594635, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_594635 != nil:
    section.add "X-Amz-Target", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Signature")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Signature", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Content-Sha256", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Date")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Date", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Credential")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Credential", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Security-Token")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Security-Token", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Algorithm")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Algorithm", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-SignedHeaders", valid_594642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594644: Call_StopTrigger_594632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_594644.validator(path, query, header, formData, body)
  let scheme = call_594644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594644.url(scheme.get, call_594644.host, call_594644.base,
                         call_594644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594644, url, valid)

proc call*(call_594645: Call_StopTrigger_594632; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_594646 = newJObject()
  if body != nil:
    body_594646 = body
  result = call_594645.call(nil, nil, nil, nil, body_594646)

var stopTrigger* = Call_StopTrigger_594632(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_594633,
                                        base: "/", url: url_StopTrigger_594634,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594647 = ref object of OpenApiRestCall_592364
proc url_TagResource_594649(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_594648(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594650 = header.getOrDefault("X-Amz-Target")
  valid_594650 = validateParameter(valid_594650, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_594650 != nil:
    section.add "X-Amz-Target", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Signature")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Signature", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Content-Sha256", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Date")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Date", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Credential")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Credential", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Security-Token")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Security-Token", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Algorithm")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Algorithm", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-SignedHeaders", valid_594657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594659: Call_TagResource_594647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_594659.validator(path, query, header, formData, body)
  let scheme = call_594659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594659.url(scheme.get, call_594659.host, call_594659.base,
                         call_594659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594659, url, valid)

proc call*(call_594660: Call_TagResource_594647; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_594661 = newJObject()
  if body != nil:
    body_594661 = body
  result = call_594660.call(nil, nil, nil, nil, body_594661)

var tagResource* = Call_TagResource_594647(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_594648,
                                        base: "/", url: url_TagResource_594649,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594662 = ref object of OpenApiRestCall_592364
proc url_UntagResource_594664(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_594663(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594665 = header.getOrDefault("X-Amz-Target")
  valid_594665 = validateParameter(valid_594665, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_594665 != nil:
    section.add "X-Amz-Target", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Signature")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Signature", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Content-Sha256", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Date")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Date", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Credential")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Credential", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Security-Token")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Security-Token", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Algorithm")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Algorithm", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-SignedHeaders", valid_594672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594674: Call_UntagResource_594662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_594674.validator(path, query, header, formData, body)
  let scheme = call_594674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594674.url(scheme.get, call_594674.host, call_594674.base,
                         call_594674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594674, url, valid)

proc call*(call_594675: Call_UntagResource_594662; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_594676 = newJObject()
  if body != nil:
    body_594676 = body
  result = call_594675.call(nil, nil, nil, nil, body_594676)

var untagResource* = Call_UntagResource_594662(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_594663, base: "/", url: url_UntagResource_594664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_594677 = ref object of OpenApiRestCall_592364
proc url_UpdateClassifier_594679(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateClassifier_594678(path: JsonNode; query: JsonNode;
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
  var valid_594680 = header.getOrDefault("X-Amz-Target")
  valid_594680 = validateParameter(valid_594680, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_594680 != nil:
    section.add "X-Amz-Target", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Signature")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Signature", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-Content-Sha256", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Date")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Date", valid_594683
  var valid_594684 = header.getOrDefault("X-Amz-Credential")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-Credential", valid_594684
  var valid_594685 = header.getOrDefault("X-Amz-Security-Token")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Security-Token", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-Algorithm")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Algorithm", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-SignedHeaders", valid_594687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594689: Call_UpdateClassifier_594677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_594689.validator(path, query, header, formData, body)
  let scheme = call_594689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594689.url(scheme.get, call_594689.host, call_594689.base,
                         call_594689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594689, url, valid)

proc call*(call_594690: Call_UpdateClassifier_594677; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_594691 = newJObject()
  if body != nil:
    body_594691 = body
  result = call_594690.call(nil, nil, nil, nil, body_594691)

var updateClassifier* = Call_UpdateClassifier_594677(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_594678, base: "/",
    url: url_UpdateClassifier_594679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_594692 = ref object of OpenApiRestCall_592364
proc url_UpdateConnection_594694(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConnection_594693(path: JsonNode; query: JsonNode;
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
  var valid_594695 = header.getOrDefault("X-Amz-Target")
  valid_594695 = validateParameter(valid_594695, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_594695 != nil:
    section.add "X-Amz-Target", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Signature")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Signature", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Content-Sha256", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Date")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Date", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Credential")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Credential", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Security-Token")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Security-Token", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Algorithm")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Algorithm", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-SignedHeaders", valid_594702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594704: Call_UpdateConnection_594692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_594704.validator(path, query, header, formData, body)
  let scheme = call_594704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594704.url(scheme.get, call_594704.host, call_594704.base,
                         call_594704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594704, url, valid)

proc call*(call_594705: Call_UpdateConnection_594692; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_594706 = newJObject()
  if body != nil:
    body_594706 = body
  result = call_594705.call(nil, nil, nil, nil, body_594706)

var updateConnection* = Call_UpdateConnection_594692(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_594693, base: "/",
    url: url_UpdateConnection_594694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_594707 = ref object of OpenApiRestCall_592364
proc url_UpdateCrawler_594709(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawler_594708(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594710 = header.getOrDefault("X-Amz-Target")
  valid_594710 = validateParameter(valid_594710, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_594710 != nil:
    section.add "X-Amz-Target", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Signature")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Signature", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Content-Sha256", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Date")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Date", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Credential")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Credential", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-Security-Token")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-Security-Token", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Algorithm")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Algorithm", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-SignedHeaders", valid_594717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594719: Call_UpdateCrawler_594707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_594719.validator(path, query, header, formData, body)
  let scheme = call_594719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594719.url(scheme.get, call_594719.host, call_594719.base,
                         call_594719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594719, url, valid)

proc call*(call_594720: Call_UpdateCrawler_594707; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_594721 = newJObject()
  if body != nil:
    body_594721 = body
  result = call_594720.call(nil, nil, nil, nil, body_594721)

var updateCrawler* = Call_UpdateCrawler_594707(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_594708, base: "/", url: url_UpdateCrawler_594709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_594722 = ref object of OpenApiRestCall_592364
proc url_UpdateCrawlerSchedule_594724(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCrawlerSchedule_594723(path: JsonNode; query: JsonNode;
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
  var valid_594725 = header.getOrDefault("X-Amz-Target")
  valid_594725 = validateParameter(valid_594725, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_594725 != nil:
    section.add "X-Amz-Target", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Signature")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Signature", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-Content-Sha256", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Date")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Date", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Credential")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Credential", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Security-Token")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Security-Token", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Algorithm")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Algorithm", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-SignedHeaders", valid_594732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594734: Call_UpdateCrawlerSchedule_594722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_594734.validator(path, query, header, formData, body)
  let scheme = call_594734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594734.url(scheme.get, call_594734.host, call_594734.base,
                         call_594734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594734, url, valid)

proc call*(call_594735: Call_UpdateCrawlerSchedule_594722; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_594736 = newJObject()
  if body != nil:
    body_594736 = body
  result = call_594735.call(nil, nil, nil, nil, body_594736)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_594722(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_594723, base: "/",
    url: url_UpdateCrawlerSchedule_594724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_594737 = ref object of OpenApiRestCall_592364
proc url_UpdateDatabase_594739(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDatabase_594738(path: JsonNode; query: JsonNode;
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
  var valid_594740 = header.getOrDefault("X-Amz-Target")
  valid_594740 = validateParameter(valid_594740, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_594740 != nil:
    section.add "X-Amz-Target", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Signature")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Signature", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Content-Sha256", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Date")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Date", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Credential")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Credential", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Security-Token")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Security-Token", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Algorithm")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Algorithm", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-SignedHeaders", valid_594747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594749: Call_UpdateDatabase_594737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_594749.validator(path, query, header, formData, body)
  let scheme = call_594749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594749.url(scheme.get, call_594749.host, call_594749.base,
                         call_594749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594749, url, valid)

proc call*(call_594750: Call_UpdateDatabase_594737; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_594751 = newJObject()
  if body != nil:
    body_594751 = body
  result = call_594750.call(nil, nil, nil, nil, body_594751)

var updateDatabase* = Call_UpdateDatabase_594737(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_594738, base: "/", url: url_UpdateDatabase_594739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_594752 = ref object of OpenApiRestCall_592364
proc url_UpdateDevEndpoint_594754(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDevEndpoint_594753(path: JsonNode; query: JsonNode;
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
  var valid_594755 = header.getOrDefault("X-Amz-Target")
  valid_594755 = validateParameter(valid_594755, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_594755 != nil:
    section.add "X-Amz-Target", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Signature")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Signature", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Content-Sha256", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Date")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Date", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Credential")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Credential", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Security-Token")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Security-Token", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-Algorithm")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Algorithm", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-SignedHeaders", valid_594762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594764: Call_UpdateDevEndpoint_594752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_594764.validator(path, query, header, formData, body)
  let scheme = call_594764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594764.url(scheme.get, call_594764.host, call_594764.base,
                         call_594764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594764, url, valid)

proc call*(call_594765: Call_UpdateDevEndpoint_594752; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_594766 = newJObject()
  if body != nil:
    body_594766 = body
  result = call_594765.call(nil, nil, nil, nil, body_594766)

var updateDevEndpoint* = Call_UpdateDevEndpoint_594752(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_594753, base: "/",
    url: url_UpdateDevEndpoint_594754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_594767 = ref object of OpenApiRestCall_592364
proc url_UpdateJob_594769(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateJob_594768(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594770 = header.getOrDefault("X-Amz-Target")
  valid_594770 = validateParameter(valid_594770, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_594770 != nil:
    section.add "X-Amz-Target", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Signature")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Signature", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-Content-Sha256", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Date")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Date", valid_594773
  var valid_594774 = header.getOrDefault("X-Amz-Credential")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "X-Amz-Credential", valid_594774
  var valid_594775 = header.getOrDefault("X-Amz-Security-Token")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Security-Token", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-Algorithm")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Algorithm", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-SignedHeaders", valid_594777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594779: Call_UpdateJob_594767; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_594779.validator(path, query, header, formData, body)
  let scheme = call_594779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594779.url(scheme.get, call_594779.host, call_594779.base,
                         call_594779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594779, url, valid)

proc call*(call_594780: Call_UpdateJob_594767; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_594781 = newJObject()
  if body != nil:
    body_594781 = body
  result = call_594780.call(nil, nil, nil, nil, body_594781)

var updateJob* = Call_UpdateJob_594767(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_594768,
                                    base: "/", url: url_UpdateJob_594769,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_594782 = ref object of OpenApiRestCall_592364
proc url_UpdateMLTransform_594784(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMLTransform_594783(path: JsonNode; query: JsonNode;
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
  var valid_594785 = header.getOrDefault("X-Amz-Target")
  valid_594785 = validateParameter(valid_594785, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_594785 != nil:
    section.add "X-Amz-Target", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-Signature")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-Signature", valid_594786
  var valid_594787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "X-Amz-Content-Sha256", valid_594787
  var valid_594788 = header.getOrDefault("X-Amz-Date")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "X-Amz-Date", valid_594788
  var valid_594789 = header.getOrDefault("X-Amz-Credential")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "X-Amz-Credential", valid_594789
  var valid_594790 = header.getOrDefault("X-Amz-Security-Token")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Security-Token", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-Algorithm")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Algorithm", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-SignedHeaders", valid_594792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594794: Call_UpdateMLTransform_594782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_594794.validator(path, query, header, formData, body)
  let scheme = call_594794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594794.url(scheme.get, call_594794.host, call_594794.base,
                         call_594794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594794, url, valid)

proc call*(call_594795: Call_UpdateMLTransform_594782; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_594796 = newJObject()
  if body != nil:
    body_594796 = body
  result = call_594795.call(nil, nil, nil, nil, body_594796)

var updateMLTransform* = Call_UpdateMLTransform_594782(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_594783, base: "/",
    url: url_UpdateMLTransform_594784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_594797 = ref object of OpenApiRestCall_592364
proc url_UpdatePartition_594799(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePartition_594798(path: JsonNode; query: JsonNode;
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
  var valid_594800 = header.getOrDefault("X-Amz-Target")
  valid_594800 = validateParameter(valid_594800, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_594800 != nil:
    section.add "X-Amz-Target", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-Signature")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Signature", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-Content-Sha256", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-Date")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Date", valid_594803
  var valid_594804 = header.getOrDefault("X-Amz-Credential")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "X-Amz-Credential", valid_594804
  var valid_594805 = header.getOrDefault("X-Amz-Security-Token")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Security-Token", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-Algorithm")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Algorithm", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-SignedHeaders", valid_594807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594809: Call_UpdatePartition_594797; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_594809.validator(path, query, header, formData, body)
  let scheme = call_594809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594809.url(scheme.get, call_594809.host, call_594809.base,
                         call_594809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594809, url, valid)

proc call*(call_594810: Call_UpdatePartition_594797; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_594811 = newJObject()
  if body != nil:
    body_594811 = body
  result = call_594810.call(nil, nil, nil, nil, body_594811)

var updatePartition* = Call_UpdatePartition_594797(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_594798, base: "/", url: url_UpdatePartition_594799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_594812 = ref object of OpenApiRestCall_592364
proc url_UpdateTable_594814(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTable_594813(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594815 = header.getOrDefault("X-Amz-Target")
  valid_594815 = validateParameter(valid_594815, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_594815 != nil:
    section.add "X-Amz-Target", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Signature")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Signature", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-Content-Sha256", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Date")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Date", valid_594818
  var valid_594819 = header.getOrDefault("X-Amz-Credential")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "X-Amz-Credential", valid_594819
  var valid_594820 = header.getOrDefault("X-Amz-Security-Token")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-Security-Token", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-Algorithm")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-Algorithm", valid_594821
  var valid_594822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "X-Amz-SignedHeaders", valid_594822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594824: Call_UpdateTable_594812; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_594824.validator(path, query, header, formData, body)
  let scheme = call_594824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594824.url(scheme.get, call_594824.host, call_594824.base,
                         call_594824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594824, url, valid)

proc call*(call_594825: Call_UpdateTable_594812; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_594826 = newJObject()
  if body != nil:
    body_594826 = body
  result = call_594825.call(nil, nil, nil, nil, body_594826)

var updateTable* = Call_UpdateTable_594812(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_594813,
                                        base: "/", url: url_UpdateTable_594814,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_594827 = ref object of OpenApiRestCall_592364
proc url_UpdateTrigger_594829(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTrigger_594828(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594830 = header.getOrDefault("X-Amz-Target")
  valid_594830 = validateParameter(valid_594830, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_594830 != nil:
    section.add "X-Amz-Target", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Signature")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Signature", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Content-Sha256", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Date")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Date", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Credential")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Credential", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-Security-Token")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-Security-Token", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-Algorithm")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Algorithm", valid_594836
  var valid_594837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-SignedHeaders", valid_594837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594839: Call_UpdateTrigger_594827; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_594839.validator(path, query, header, formData, body)
  let scheme = call_594839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594839.url(scheme.get, call_594839.host, call_594839.base,
                         call_594839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594839, url, valid)

proc call*(call_594840: Call_UpdateTrigger_594827; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_594841 = newJObject()
  if body != nil:
    body_594841 = body
  result = call_594840.call(nil, nil, nil, nil, body_594841)

var updateTrigger* = Call_UpdateTrigger_594827(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_594828, base: "/", url: url_UpdateTrigger_594829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_594842 = ref object of OpenApiRestCall_592364
proc url_UpdateUserDefinedFunction_594844(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateUserDefinedFunction_594843(path: JsonNode; query: JsonNode;
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
  var valid_594845 = header.getOrDefault("X-Amz-Target")
  valid_594845 = validateParameter(valid_594845, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_594845 != nil:
    section.add "X-Amz-Target", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Signature")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Signature", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Content-Sha256", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Date")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Date", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Credential")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Credential", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-Security-Token")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-Security-Token", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-Algorithm")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Algorithm", valid_594851
  var valid_594852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-SignedHeaders", valid_594852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594854: Call_UpdateUserDefinedFunction_594842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_594854.validator(path, query, header, formData, body)
  let scheme = call_594854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594854.url(scheme.get, call_594854.host, call_594854.base,
                         call_594854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594854, url, valid)

proc call*(call_594855: Call_UpdateUserDefinedFunction_594842; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_594856 = newJObject()
  if body != nil:
    body_594856 = body
  result = call_594855.call(nil, nil, nil, nil, body_594856)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_594842(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_594843, base: "/",
    url: url_UpdateUserDefinedFunction_594844,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_594857 = ref object of OpenApiRestCall_592364
proc url_UpdateWorkflow_594859(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWorkflow_594858(path: JsonNode; query: JsonNode;
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
  var valid_594860 = header.getOrDefault("X-Amz-Target")
  valid_594860 = validateParameter(valid_594860, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_594860 != nil:
    section.add "X-Amz-Target", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-Signature")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Signature", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-Content-Sha256", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-Date")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Date", valid_594863
  var valid_594864 = header.getOrDefault("X-Amz-Credential")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-Credential", valid_594864
  var valid_594865 = header.getOrDefault("X-Amz-Security-Token")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Security-Token", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-Algorithm")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Algorithm", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-SignedHeaders", valid_594867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594869: Call_UpdateWorkflow_594857; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_594869.validator(path, query, header, formData, body)
  let scheme = call_594869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594869.url(scheme.get, call_594869.host, call_594869.base,
                         call_594869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594869, url, valid)

proc call*(call_594870: Call_UpdateWorkflow_594857; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_594871 = newJObject()
  if body != nil:
    body_594871 = body
  result = call_594870.call(nil, nil, nil, nil, body_594871)

var updateWorkflow* = Call_UpdateWorkflow_594857(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_594858, base: "/", url: url_UpdateWorkflow_594859,
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

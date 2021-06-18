
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2017-03-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Http: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20170325_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateCloudFrontOriginAccessIdentity20170325_402656479(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20170325_402656478(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656488: Call_CreateCloudFrontOriginAccessIdentity20170325_402656477;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

proc call*(call_402656489: Call_CreateCloudFrontOriginAccessIdentity20170325_402656477;
           body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20170325
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createCloudFrontOriginAccessIdentity20170325* = Call_CreateCloudFrontOriginAccessIdentity20170325_402656477(
    name: "createCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20170325_402656478,
    base: "/", makeUrl: url_CreateCloudFrontOriginAccessIdentity20170325_402656479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20170325_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListCloudFrontOriginAccessIdentities20170325_402656296(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20170325_402656295(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists origin access identities.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## origin 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## identities 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## body. 
  section = newJObject()
  var valid_402656375 = query.getOrDefault("Marker")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "Marker", valid_402656375
  var valid_402656376 = query.getOrDefault("MaxItems")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "MaxItems", valid_402656376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Security-Token", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Signature")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Signature", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Algorithm", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Date")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Date", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Credential")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Credential", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656397: Call_ListCloudFrontOriginAccessIdentities20170325_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists origin access identities.
                                                                                         ## 
  let valid = call_402656397.validator(path, query, header, formData, body, _)
  let scheme = call_402656397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656397.makeUrl(scheme.get, call_402656397.host, call_402656397.base,
                                   call_402656397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656397, uri, valid, _)

proc call*(call_402656446: Call_ListCloudFrontOriginAccessIdentities20170325_402656294;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20170325
  ## Lists origin access identities.
  ##   Marker: string
                                    ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## MaxItems: string
                                                                                                                                                                                                                                                                                                                                                                                                                                  ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## origin 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## identities 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body. 
  var query_402656447 = newJObject()
  add(query_402656447, "Marker", newJString(Marker))
  add(query_402656447, "MaxItems", newJString(MaxItems))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20170325* = Call_ListCloudFrontOriginAccessIdentities20170325_402656294(
    name: "listCloudFrontOriginAccessIdentities20170325",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20170325_402656295,
    base: "/", makeUrl: url_ListCloudFrontOriginAccessIdentities20170325_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20170325_402656506 = ref object of OpenApiRestCall_402656044
proc url_CreateDistribution20170325_402656508(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistribution20170325_402656507(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656517: Call_CreateDistribution20170325_402656506;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
                                                                                         ## 
  let valid = call_402656517.validator(path, query, header, formData, body, _)
  let scheme = call_402656517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656517.makeUrl(scheme.get, call_402656517.host, call_402656517.base,
                                   call_402656517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656517, uri, valid, _)

proc call*(call_402656518: Call_CreateDistribution20170325_402656506;
           body: JsonNode): Recallable =
  ## createDistribution20170325
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ##   
                                                                                                                                                                            ## body: JObject (required)
  var body_402656519 = newJObject()
  if body != nil:
    body_402656519 = body
  result = call_402656518.call(nil, nil, nil, nil, body_402656519)

var createDistribution20170325* = Call_CreateDistribution20170325_402656506(
    name: "createDistribution20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution",
    validator: validate_CreateDistribution20170325_402656507, base: "/",
    makeUrl: url_CreateDistribution20170325_402656508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20170325_402656491 = ref object of OpenApiRestCall_402656044
proc url_ListDistributions20170325_402656493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributions20170325_402656492(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List distributions. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                            ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                            ##           
                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## distributions 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## body.
  section = newJObject()
  var valid_402656494 = query.getOrDefault("Marker")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "Marker", valid_402656494
  var valid_402656495 = query.getOrDefault("MaxItems")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "MaxItems", valid_402656495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656496 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Security-Token", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Signature")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Signature", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Algorithm", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Date")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Date", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Credential")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Credential", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656503: Call_ListDistributions20170325_402656491;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List distributions. 
                                                                                         ## 
  let valid = call_402656503.validator(path, query, header, formData, body, _)
  let scheme = call_402656503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656503.makeUrl(scheme.get, call_402656503.host, call_402656503.base,
                                   call_402656503.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656503, uri, valid, _)

proc call*(call_402656504: Call_ListDistributions20170325_402656491;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributions20170325
  ## List distributions. 
  ##   Marker: string
                         ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                   ## MaxItems: string
                                                                                                                                                                                                                                                                                                                                                                                                                   ##           
                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## distributions 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## body.
  var query_402656505 = newJObject()
  add(query_402656505, "Marker", newJString(Marker))
  add(query_402656505, "MaxItems", newJString(MaxItems))
  result = call_402656504.call(nil, query_402656505, nil, nil, nil)

var listDistributions20170325* = Call_ListDistributions20170325_402656491(
    name: "listDistributions20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution",
    validator: validate_ListDistributions20170325_402656492, base: "/",
    makeUrl: url_ListDistributions20170325_402656493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20170325_402656520 = ref object of OpenApiRestCall_402656044
proc url_CreateDistributionWithTags20170325_402656522(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionWithTags20170325_402656521(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new distribution with tags.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `WithTags` field"
  var valid_402656523 = query.getOrDefault("WithTags")
  valid_402656523 = validateParameter(valid_402656523, JBool, required = true,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "WithTags", valid_402656523
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656524 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Security-Token", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Signature")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Signature", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Algorithm", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Date")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Date", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Credential")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Credential", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656532: Call_CreateDistributionWithTags20170325_402656520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new distribution with tags.
                                                                                         ## 
  let valid = call_402656532.validator(path, query, header, formData, body, _)
  let scheme = call_402656532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656532.makeUrl(scheme.get, call_402656532.host, call_402656532.base,
                                   call_402656532.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656532, uri, valid, _)

proc call*(call_402656533: Call_CreateDistributionWithTags20170325_402656520;
           WithTags: bool; body: JsonNode): Recallable =
  ## createDistributionWithTags20170325
  ## Create a new distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_402656534 = newJObject()
  var body_402656535 = newJObject()
  add(query_402656534, "WithTags", newJBool(WithTags))
  if body != nil:
    body_402656535 = body
  result = call_402656533.call(nil, query_402656534, nil, nil, body_402656535)

var createDistributionWithTags20170325* = Call_CreateDistributionWithTags20170325_402656520(
    name: "createDistributionWithTags20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20170325_402656521, base: "/",
    makeUrl: url_CreateDistributionWithTags20170325_402656522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20170325_402656564 = ref object of OpenApiRestCall_402656044
proc url_CreateInvalidation20170325_402656566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path,
         "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
                 (kind: VariableSegment, value: "DistributionId"),
                 (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20170325_402656565(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new invalidation. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
                                 ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DistributionId` field"
  var valid_402656567 = path.getOrDefault("DistributionId")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true,
                                      default = nil)
  if valid_402656567 != nil:
    section.add "DistributionId", valid_402656567
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_CreateInvalidation20170325_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new invalidation. 
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_CreateInvalidation20170325_402656564;
           DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20170325
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
                                ##                 : The distribution's id.
  ##   body: 
                                                                           ## JObject (required)
  var path_402656578 = newJObject()
  var body_402656579 = newJObject()
  add(path_402656578, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_402656579 = body
  result = call_402656577.call(path_402656578, nil, nil, nil, body_402656579)

var createInvalidation20170325* = Call_CreateInvalidation20170325_402656564(
    name: "createInvalidation20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20170325_402656565, base: "/",
    makeUrl: url_CreateInvalidation20170325_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20170325_402656536 = ref object of OpenApiRestCall_402656044
proc url_ListInvalidations20170325_402656538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path,
         "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
                 (kind: VariableSegment, value: "DistributionId"),
                 (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20170325_402656537(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists invalidation batches. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
                                 ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DistributionId` field"
  var valid_402656550 = path.getOrDefault("DistributionId")
  valid_402656550 = validateParameter(valid_402656550, JString, required = true,
                                      default = nil)
  if valid_402656550 != nil:
    section.add "DistributionId", valid_402656550
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## invalidation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## batches 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body.
  section = newJObject()
  var valid_402656551 = query.getOrDefault("Marker")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "Marker", valid_402656551
  var valid_402656552 = query.getOrDefault("MaxItems")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "MaxItems", valid_402656552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656560: Call_ListInvalidations20170325_402656536;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists invalidation batches. 
                                                                                         ## 
  let valid = call_402656560.validator(path, query, header, formData, body, _)
  let scheme = call_402656560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656560.makeUrl(scheme.get, call_402656560.host, call_402656560.base,
                                   call_402656560.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656560, uri, valid, _)

proc call*(call_402656561: Call_ListInvalidations20170325_402656536;
           DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20170325
  ## Lists invalidation batches. 
  ##   DistributionId: string (required)
                                 ##                 : The distribution's ID.
  ##   
                                                                            ## Marker: string
                                                                            ##         
                                                                            ## : 
                                                                            ## Use 
                                                                            ## this 
                                                                            ## parameter 
                                                                            ## when 
                                                                            ## paginating 
                                                                            ## results 
                                                                            ## to 
                                                                            ## indicate 
                                                                            ## where 
                                                                            ## to 
                                                                            ## begin 
                                                                            ## in 
                                                                            ## your 
                                                                            ## list 
                                                                            ## of 
                                                                            ## invalidation 
                                                                            ## batches. 
                                                                            ## Because 
                                                                            ## the 
                                                                            ## results 
                                                                            ## are 
                                                                            ## returned 
                                                                            ## in 
                                                                            ## decreasing 
                                                                            ## order 
                                                                            ## from 
                                                                            ## most 
                                                                            ## recent 
                                                                            ## to 
                                                                            ## oldest, 
                                                                            ## the 
                                                                            ## most 
                                                                            ## recent 
                                                                            ## results 
                                                                            ## are 
                                                                            ## on 
                                                                            ## the 
                                                                            ## first 
                                                                            ## page, 
                                                                            ## the 
                                                                            ## second 
                                                                            ## page 
                                                                            ## will 
                                                                            ## contain 
                                                                            ## earlier 
                                                                            ## results, 
                                                                            ## and 
                                                                            ## so 
                                                                            ## on. 
                                                                            ## To 
                                                                            ## get 
                                                                            ## the 
                                                                            ## next 
                                                                            ## page 
                                                                            ## of 
                                                                            ## results, 
                                                                            ## set 
                                                                            ## <code>Marker</code> 
                                                                            ## to 
                                                                            ## the 
                                                                            ## value 
                                                                            ## of 
                                                                            ## the 
                                                                            ## <code>NextMarker</code> 
                                                                            ## from 
                                                                            ## the 
                                                                            ## current 
                                                                            ## page's 
                                                                            ## response. 
                                                                            ## This 
                                                                            ## value 
                                                                            ## is 
                                                                            ## the 
                                                                            ## same 
                                                                            ## as 
                                                                            ## the 
                                                                            ## ID 
                                                                            ## of 
                                                                            ## the 
                                                                            ## last 
                                                                            ## invalidation 
                                                                            ## batch 
                                                                            ## on 
                                                                            ## that 
                                                                            ## page. 
  ##   
                                                                                     ## MaxItems: string
                                                                                     ##           
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## maximum 
                                                                                     ## number 
                                                                                     ## of 
                                                                                     ## invalidation 
                                                                                     ## batches 
                                                                                     ## that 
                                                                                     ## you 
                                                                                     ## want 
                                                                                     ## in 
                                                                                     ## the 
                                                                                     ## response 
                                                                                     ## body.
  var path_402656562 = newJObject()
  var query_402656563 = newJObject()
  add(path_402656562, "DistributionId", newJString(DistributionId))
  add(query_402656563, "Marker", newJString(Marker))
  add(query_402656563, "MaxItems", newJString(MaxItems))
  result = call_402656561.call(path_402656562, query_402656563, nil, nil, nil)

var listInvalidations20170325* = Call_ListInvalidations20170325_402656536(
    name: "listInvalidations20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20170325_402656537, base: "/",
    makeUrl: url_ListInvalidations20170325_402656538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20170325_402656595 = ref object of OpenApiRestCall_402656044
proc url_CreateStreamingDistribution20170325_402656597(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistribution20170325_402656596(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_CreateStreamingDistribution20170325_402656595;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateStreamingDistribution20170325_402656595;
           body: JsonNode): Recallable =
  ## createStreamingDistribution20170325
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var createStreamingDistribution20170325* = Call_CreateStreamingDistribution20170325_402656595(
    name: "createStreamingDistribution20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution",
    validator: validate_CreateStreamingDistribution20170325_402656596,
    base: "/", makeUrl: url_CreateStreamingDistribution20170325_402656597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20170325_402656580 = ref object of OpenApiRestCall_402656044
proc url_ListStreamingDistributions20170325_402656582(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamingDistributions20170325_402656581(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List streaming distributions. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   
                                                                                                                         ## MaxItems: JString
                                                                                                                         ##           
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## value 
                                                                                                                         ## that 
                                                                                                                         ## you 
                                                                                                                         ## provided 
                                                                                                                         ## for 
                                                                                                                         ## the 
                                                                                                                         ## <code>MaxItems</code> 
                                                                                                                         ## request 
                                                                                                                         ## parameter.
  section = newJObject()
  var valid_402656583 = query.getOrDefault("Marker")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "Marker", valid_402656583
  var valid_402656584 = query.getOrDefault("MaxItems")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "MaxItems", valid_402656584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656585 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Security-Token", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Signature")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Signature", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Algorithm", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Date")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Date", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Credential")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Credential", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656592: Call_ListStreamingDistributions20170325_402656580;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List streaming distributions. 
                                                                                         ## 
  let valid = call_402656592.validator(path, query, header, formData, body, _)
  let scheme = call_402656592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656592.makeUrl(scheme.get, call_402656592.host, call_402656592.base,
                                   call_402656592.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656592, uri, valid, _)

proc call*(call_402656593: Call_ListStreamingDistributions20170325_402656580;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20170325
  ## List streaming distributions. 
  ##   Marker: string
                                   ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   
                                                                                                                          ## MaxItems: string
                                                                                                                          ##           
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## value 
                                                                                                                          ## that 
                                                                                                                          ## you 
                                                                                                                          ## provided 
                                                                                                                          ## for 
                                                                                                                          ## the 
                                                                                                                          ## <code>MaxItems</code> 
                                                                                                                          ## request 
                                                                                                                          ## parameter.
  var query_402656594 = newJObject()
  add(query_402656594, "Marker", newJString(Marker))
  add(query_402656594, "MaxItems", newJString(MaxItems))
  result = call_402656593.call(nil, query_402656594, nil, nil, nil)

var listStreamingDistributions20170325* = Call_ListStreamingDistributions20170325_402656580(
    name: "listStreamingDistributions20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution",
    validator: validate_ListStreamingDistributions20170325_402656581, base: "/",
    makeUrl: url_ListStreamingDistributions20170325_402656582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20170325_402656609 = ref object of OpenApiRestCall_402656044
proc url_CreateStreamingDistributionWithTags20170325_402656611(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20170325_402656610(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Create a new streaming distribution with tags.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `WithTags` field"
  var valid_402656612 = query.getOrDefault("WithTags")
  valid_402656612 = validateParameter(valid_402656612, JBool, required = true,
                                      default = nil)
  if valid_402656612 != nil:
    section.add "WithTags", valid_402656612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_CreateStreamingDistributionWithTags20170325_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new streaming distribution with tags.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_CreateStreamingDistributionWithTags20170325_402656609;
           WithTags: bool; body: JsonNode): Recallable =
  ## createStreamingDistributionWithTags20170325
  ## Create a new streaming distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_402656623 = newJObject()
  var body_402656624 = newJObject()
  add(query_402656623, "WithTags", newJBool(WithTags))
  if body != nil:
    body_402656624 = body
  result = call_402656622.call(nil, query_402656623, nil, nil, body_402656624)

var createStreamingDistributionWithTags20170325* = Call_CreateStreamingDistributionWithTags20170325_402656609(
    name: "createStreamingDistributionWithTags20170325",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20170325_402656610,
    base: "/", makeUrl: url_CreateStreamingDistributionWithTags20170325_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20170325_402656625 = ref object of OpenApiRestCall_402656044
proc url_GetCloudFrontOriginAccessIdentity20170325_402656627(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20170325_402656626(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the information about an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656628 = path.getOrDefault("Id")
  valid_402656628 = validateParameter(valid_402656628, JString, required = true,
                                      default = nil)
  if valid_402656628 != nil:
    section.add "Id", valid_402656628
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656629 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Security-Token", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Signature")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Signature", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Algorithm", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Date")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Date", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Credential")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Credential", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_GetCloudFrontOriginAccessIdentity20170325_402656625;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an origin access identity. 
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_GetCloudFrontOriginAccessIdentity20170325_402656625;
           Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20170325
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
                                                          ##     : The identity's ID.
  var path_402656638 = newJObject()
  add(path_402656638, "Id", newJString(Id))
  result = call_402656637.call(path_402656638, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20170325* = Call_GetCloudFrontOriginAccessIdentity20170325_402656625(
    name: "getCloudFrontOriginAccessIdentity20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20170325_402656626,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentity20170325_402656627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20170325_402656639 = ref object of OpenApiRestCall_402656044
proc url_DeleteCloudFrontOriginAccessIdentity20170325_402656641(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20170325_402656640(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Delete an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656642 = path.getOrDefault("Id")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true,
                                      default = nil)
  if valid_402656642 != nil:
    section.add "Id", valid_402656642
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                            ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                            ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                       ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                             ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                         ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("If-Match")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "If-Match", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Algorithm", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Date")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Date", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Credential")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Credential", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_DeleteCloudFrontOriginAccessIdentity20170325_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an origin access identity. 
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DeleteCloudFrontOriginAccessIdentity20170325_402656639;
           Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20170325
  ## Delete an origin access identity. 
  ##   Id: string (required)
                                       ##     : The origin access identity's ID.
  var path_402656653 = newJObject()
  add(path_402656653, "Id", newJString(Id))
  result = call_402656652.call(path_402656653, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20170325* = Call_DeleteCloudFrontOriginAccessIdentity20170325_402656639(
    name: "deleteCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20170325_402656640,
    base: "/", makeUrl: url_DeleteCloudFrontOriginAccessIdentity20170325_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20170325_402656654 = ref object of OpenApiRestCall_402656044
proc url_GetDistribution20170325_402656656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20170325_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about a distribution. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656657 = path.getOrDefault("Id")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true,
                                      default = nil)
  if valid_402656657 != nil:
    section.add "Id", valid_402656657
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656665: Call_GetDistribution20170325_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about a distribution. 
                                                                                         ## 
  let valid = call_402656665.validator(path, query, header, formData, body, _)
  let scheme = call_402656665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656665.makeUrl(scheme.get, call_402656665.host, call_402656665.base,
                                   call_402656665.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656665, uri, valid, _)

proc call*(call_402656666: Call_GetDistribution20170325_402656654; Id: string): Recallable =
  ## getDistribution20170325
  ## Get the information about a distribution. 
  ##   Id: string (required)
                                               ##     : The distribution's ID.
  var path_402656667 = newJObject()
  add(path_402656667, "Id", newJString(Id))
  result = call_402656666.call(path_402656667, nil, nil, nil, nil)

var getDistribution20170325* = Call_GetDistribution20170325_402656654(
    name: "getDistribution20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution/{Id}",
    validator: validate_GetDistribution20170325_402656655, base: "/",
    makeUrl: url_GetDistribution20170325_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20170325_402656668 = ref object of OpenApiRestCall_402656044
proc url_DeleteDistribution20170325_402656670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20170325_402656669(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Delete a distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656671 = path.getOrDefault("Id")
  valid_402656671 = validateParameter(valid_402656671, JString, required = true,
                                      default = nil)
  if valid_402656671 != nil:
    section.add "Id", valid_402656671
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   
                                                                                                                                                                                        ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                        ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                         ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                     ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Security-Token", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Signature")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Signature", valid_402656673
  var valid_402656674 = header.getOrDefault("If-Match")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "If-Match", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656680: Call_DeleteDistribution20170325_402656668;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a distribution. 
                                                                                         ## 
  let valid = call_402656680.validator(path, query, header, formData, body, _)
  let scheme = call_402656680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656680.makeUrl(scheme.get, call_402656680.host, call_402656680.base,
                                   call_402656680.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656680, uri, valid, _)

proc call*(call_402656681: Call_DeleteDistribution20170325_402656668; Id: string): Recallable =
  ## deleteDistribution20170325
  ## Delete a distribution. 
  ##   Id: string (required)
                            ##     : The distribution ID. 
  var path_402656682 = newJObject()
  add(path_402656682, "Id", newJString(Id))
  result = call_402656681.call(path_402656682, nil, nil, nil, nil)

var deleteDistribution20170325* = Call_DeleteDistribution20170325_402656668(
    name: "deleteDistribution20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution/{Id}",
    validator: validate_DeleteDistribution20170325_402656669, base: "/",
    makeUrl: url_DeleteDistribution20170325_402656670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceLinkedRole20170325_402656683 = ref object of OpenApiRestCall_402656044
proc url_DeleteServiceLinkedRole20170325_402656685(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "RoleName" in path, "`RoleName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/service-linked-role/"),
                 (kind: VariableSegment, value: "RoleName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteServiceLinkedRole20170325_402656684(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RoleName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `RoleName` field"
  var valid_402656686 = path.getOrDefault("RoleName")
  valid_402656686 = validateParameter(valid_402656686, JString, required = true,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "RoleName", valid_402656686
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Security-Token", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Signature")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Signature", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Algorithm", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Date")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Date", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Credential")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Credential", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656694: Call_DeleteServiceLinkedRole20170325_402656683;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656694.validator(path, query, header, formData, body, _)
  let scheme = call_402656694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656694.makeUrl(scheme.get, call_402656694.host, call_402656694.base,
                                   call_402656694.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656694, uri, valid, _)

proc call*(call_402656695: Call_DeleteServiceLinkedRole20170325_402656683;
           RoleName: string): Recallable =
  ## deleteServiceLinkedRole20170325
  ##   RoleName: string (required)
  var path_402656696 = newJObject()
  add(path_402656696, "RoleName", newJString(RoleName))
  result = call_402656695.call(path_402656696, nil, nil, nil, nil)

var deleteServiceLinkedRole20170325* = Call_DeleteServiceLinkedRole20170325_402656683(
    name: "deleteServiceLinkedRole20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/service-linked-role/{RoleName}",
    validator: validate_DeleteServiceLinkedRole20170325_402656684, base: "/",
    makeUrl: url_DeleteServiceLinkedRole20170325_402656685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20170325_402656697 = ref object of OpenApiRestCall_402656044
proc url_GetStreamingDistribution20170325_402656699(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20170325_402656698(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656700 = path.getOrDefault("Id")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "Id", valid_402656700
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656701 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Security-Token", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Signature")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Signature", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Algorithm", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Date")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Date", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Credential")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Credential", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656708: Call_GetStreamingDistribution20170325_402656697;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
                                                                                         ## 
  let valid = call_402656708.validator(path, query, header, formData, body, _)
  let scheme = call_402656708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656708.makeUrl(scheme.get, call_402656708.host, call_402656708.base,
                                   call_402656708.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656708, uri, valid, _)

proc call*(call_402656709: Call_GetStreamingDistribution20170325_402656697;
           Id: string): Recallable =
  ## getStreamingDistribution20170325
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   
                                                                                                    ## Id: string (required)
                                                                                                    ##     
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## streaming 
                                                                                                    ## distribution's 
                                                                                                    ## ID.
  var path_402656710 = newJObject()
  add(path_402656710, "Id", newJString(Id))
  result = call_402656709.call(path_402656710, nil, nil, nil, nil)

var getStreamingDistribution20170325* = Call_GetStreamingDistribution20170325_402656697(
    name: "getStreamingDistribution20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20170325_402656698, base: "/",
    makeUrl: url_GetStreamingDistribution20170325_402656699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20170325_402656711 = ref object of OpenApiRestCall_402656044
proc url_DeleteStreamingDistribution20170325_402656713(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20170325_402656712(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656714 = path.getOrDefault("Id")
  valid_402656714 = validateParameter(valid_402656714, JString, required = true,
                                      default = nil)
  if valid_402656714 != nil:
    section.add "Id", valid_402656714
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656715 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Security-Token", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Signature")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Signature", valid_402656716
  var valid_402656717 = header.getOrDefault("If-Match")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "If-Match", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Algorithm", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Date")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Date", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Credential")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Credential", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656723: Call_DeleteStreamingDistribution20170325_402656711;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656723.validator(path, query, header, formData, body, _)
  let scheme = call_402656723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656723.makeUrl(scheme.get, call_402656723.host, call_402656723.base,
                                   call_402656723.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656723, uri, valid, _)

proc call*(call_402656724: Call_DeleteStreamingDistribution20170325_402656711;
           Id: string): Recallable =
  ## deleteStreamingDistribution20170325
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Id: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## distribution 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID. 
  var path_402656725 = newJObject()
  add(path_402656725, "Id", newJString(Id))
  result = call_402656724.call(path_402656725, nil, nil, nil, nil)

var deleteStreamingDistribution20170325* = Call_DeleteStreamingDistribution20170325_402656711(
    name: "deleteStreamingDistribution20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20170325_402656712,
    base: "/", makeUrl: url_DeleteStreamingDistribution20170325_402656713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20170325_402656740 = ref object of OpenApiRestCall_402656044
proc url_UpdateCloudFrontOriginAccessIdentity20170325_402656742(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20170325_402656741(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Update an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656743 = path.getOrDefault("Id")
  valid_402656743 = validateParameter(valid_402656743, JString, required = true,
                                      default = nil)
  if valid_402656743 != nil:
    section.add "Id", valid_402656743
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656744 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Security-Token", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Signature")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Signature", valid_402656745
  var valid_402656746 = header.getOrDefault("If-Match")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "If-Match", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Algorithm", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Date")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Date", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Credential")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Credential", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656753: Call_UpdateCloudFrontOriginAccessIdentity20170325_402656740;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an origin access identity. 
                                                                                         ## 
  let valid = call_402656753.validator(path, query, header, formData, body, _)
  let scheme = call_402656753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656753.makeUrl(scheme.get, call_402656753.host, call_402656753.base,
                                   call_402656753.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656753, uri, valid, _)

proc call*(call_402656754: Call_UpdateCloudFrontOriginAccessIdentity20170325_402656740;
           body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20170325
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
                               ##     : The identity's id.
  var path_402656755 = newJObject()
  var body_402656756 = newJObject()
  if body != nil:
    body_402656756 = body
  add(path_402656755, "Id", newJString(Id))
  result = call_402656754.call(path_402656755, nil, nil, nil, body_402656756)

var updateCloudFrontOriginAccessIdentity20170325* = Call_UpdateCloudFrontOriginAccessIdentity20170325_402656740(
    name: "updateCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20170325_402656741,
    base: "/", makeUrl: url_UpdateCloudFrontOriginAccessIdentity20170325_402656742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20170325_402656726 = ref object of OpenApiRestCall_402656044
proc url_GetCloudFrontOriginAccessIdentityConfig20170325_402656728(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20170325_402656727(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656729 = path.getOrDefault("Id")
  valid_402656729 = validateParameter(valid_402656729, JString, required = true,
                                      default = nil)
  if valid_402656729 != nil:
    section.add "Id", valid_402656729
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656730 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Security-Token", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Signature")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Signature", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Algorithm", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Date")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Date", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Credential")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Credential", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656737: Call_GetCloudFrontOriginAccessIdentityConfig20170325_402656726;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about an origin access identity. 
                                                                                         ## 
  let valid = call_402656737.validator(path, query, header, formData, body, _)
  let scheme = call_402656737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656737.makeUrl(scheme.get, call_402656737.host, call_402656737.base,
                                   call_402656737.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656737, uri, valid, _)

proc call*(call_402656738: Call_GetCloudFrontOriginAccessIdentityConfig20170325_402656726;
           Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20170325
  ## Get the configuration information about an origin access identity. 
  ##   Id: string 
                                                                        ## (required)
                                                                        ##     
                                                                        ## : 
                                                                        ## The 
                                                                        ## identity's 
                                                                        ## ID. 
  var path_402656739 = newJObject()
  add(path_402656739, "Id", newJString(Id))
  result = call_402656738.call(path_402656739, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20170325* = Call_GetCloudFrontOriginAccessIdentityConfig20170325_402656726(
    name: "getCloudFrontOriginAccessIdentityConfig20170325",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20170325_402656727,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentityConfig20170325_402656728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20170325_402656771 = ref object of OpenApiRestCall_402656044
proc url_UpdateDistribution20170325_402656773(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20170325_402656772(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656774 = path.getOrDefault("Id")
  valid_402656774 = validateParameter(valid_402656774, JString, required = true,
                                      default = nil)
  if valid_402656774 != nil:
    section.add "Id", valid_402656774
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                     ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                     ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                      ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                  ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656775 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Security-Token", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Signature")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Signature", valid_402656776
  var valid_402656777 = header.getOrDefault("If-Match")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "If-Match", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Algorithm", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Date")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Date", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Credential")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Credential", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656784: Call_UpdateDistribution20170325_402656771;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
                                                                                         ## 
  let valid = call_402656784.validator(path, query, header, formData, body, _)
  let scheme = call_402656784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656784.makeUrl(scheme.get, call_402656784.host, call_402656784.base,
                                   call_402656784.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656784, uri, valid, _)

proc call*(call_402656785: Call_UpdateDistribution20170325_402656771;
           body: JsonNode; Id: string): Recallable =
  ## updateDistribution20170325
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## Id: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ##     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## distribution's 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## id.
  var path_402656786 = newJObject()
  var body_402656787 = newJObject()
  if body != nil:
    body_402656787 = body
  add(path_402656786, "Id", newJString(Id))
  result = call_402656785.call(path_402656786, nil, nil, nil, body_402656787)

var updateDistribution20170325* = Call_UpdateDistribution20170325_402656771(
    name: "updateDistribution20170325", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{Id}/config",
    validator: validate_UpdateDistribution20170325_402656772, base: "/",
    makeUrl: url_UpdateDistribution20170325_402656773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20170325_402656757 = ref object of OpenApiRestCall_402656044
proc url_GetDistributionConfig20170325_402656759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20170325_402656758(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656760 = path.getOrDefault("Id")
  valid_402656760 = validateParameter(valid_402656760, JString, required = true,
                                      default = nil)
  if valid_402656760 != nil:
    section.add "Id", valid_402656760
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656761 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Security-Token", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Signature")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Signature", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Algorithm", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Date")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Date", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Credential")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Credential", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656768: Call_GetDistributionConfig20170325_402656757;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a distribution. 
                                                                                         ## 
  let valid = call_402656768.validator(path, query, header, formData, body, _)
  let scheme = call_402656768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656768.makeUrl(scheme.get, call_402656768.host, call_402656768.base,
                                   call_402656768.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656768, uri, valid, _)

proc call*(call_402656769: Call_GetDistributionConfig20170325_402656757;
           Id: string): Recallable =
  ## getDistributionConfig20170325
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
                                                             ##     : The distribution's ID.
  var path_402656770 = newJObject()
  add(path_402656770, "Id", newJString(Id))
  result = call_402656769.call(path_402656770, nil, nil, nil, nil)

var getDistributionConfig20170325* = Call_GetDistributionConfig20170325_402656757(
    name: "getDistributionConfig20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20170325_402656758, base: "/",
    makeUrl: url_GetDistributionConfig20170325_402656759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20170325_402656788 = ref object of OpenApiRestCall_402656044
proc url_GetInvalidation20170325_402656790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path,
         "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
                 (kind: VariableSegment, value: "DistributionId"),
                 (kind: ConstantSegment, value: "/invalidation/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20170325_402656789(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about an invalidation. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
                                 ##                 : The distribution's ID.
  ##   Id: 
                                                                            ## JString (required)
                                                                            ##     
                                                                            ## : 
                                                                            ## The 
                                                                            ## identifier 
                                                                            ## for 
                                                                            ## the 
                                                                            ## invalidation 
                                                                            ## request, 
                                                                            ## for 
                                                                            ## example, 
                                                                            ## <code>IDFDVBD632BHDS5</code>.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DistributionId` field"
  var valid_402656791 = path.getOrDefault("DistributionId")
  valid_402656791 = validateParameter(valid_402656791, JString, required = true,
                                      default = nil)
  if valid_402656791 != nil:
    section.add "DistributionId", valid_402656791
  var valid_402656792 = path.getOrDefault("Id")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true,
                                      default = nil)
  if valid_402656792 != nil:
    section.add "Id", valid_402656792
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656800: Call_GetInvalidation20170325_402656788;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an invalidation. 
                                                                                         ## 
  let valid = call_402656800.validator(path, query, header, formData, body, _)
  let scheme = call_402656800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656800.makeUrl(scheme.get, call_402656800.host, call_402656800.base,
                                   call_402656800.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656800, uri, valid, _)

proc call*(call_402656801: Call_GetInvalidation20170325_402656788;
           DistributionId: string; Id: string): Recallable =
  ## getInvalidation20170325
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
                                                ##                 : The distribution's ID.
  ##   
                                                                                           ## Id: string (required)
                                                                                           ##     
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## identifier 
                                                                                           ## for 
                                                                                           ## the 
                                                                                           ## invalidation 
                                                                                           ## request, 
                                                                                           ## for 
                                                                                           ## example, 
                                                                                           ## <code>IDFDVBD632BHDS5</code>.
  var path_402656802 = newJObject()
  add(path_402656802, "DistributionId", newJString(DistributionId))
  add(path_402656802, "Id", newJString(Id))
  result = call_402656801.call(path_402656802, nil, nil, nil, nil)

var getInvalidation20170325* = Call_GetInvalidation20170325_402656788(
    name: "getInvalidation20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20170325_402656789, base: "/",
    makeUrl: url_GetInvalidation20170325_402656790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20170325_402656817 = ref object of OpenApiRestCall_402656044
proc url_UpdateStreamingDistribution20170325_402656819(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20170325_402656818(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update a streaming distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656820 = path.getOrDefault("Id")
  valid_402656820 = validateParameter(valid_402656820, JString, required = true,
                                      default = nil)
  if valid_402656820 != nil:
    section.add "Id", valid_402656820
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                               ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                               ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                          ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                            ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656821 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Security-Token", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Signature")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Signature", valid_402656822
  var valid_402656823 = header.getOrDefault("If-Match")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "If-Match", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Algorithm", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Date")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Date", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Credential")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Credential", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656830: Call_UpdateStreamingDistribution20170325_402656817;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a streaming distribution. 
                                                                                         ## 
  let valid = call_402656830.validator(path, query, header, formData, body, _)
  let scheme = call_402656830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656830.makeUrl(scheme.get, call_402656830.host, call_402656830.base,
                                   call_402656830.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656830, uri, valid, _)

proc call*(call_402656831: Call_UpdateStreamingDistribution20170325_402656817;
           body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20170325
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
                               ##     : The streaming distribution's id.
  var path_402656832 = newJObject()
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  add(path_402656832, "Id", newJString(Id))
  result = call_402656831.call(path_402656832, nil, nil, nil, body_402656833)

var updateStreamingDistribution20170325* = Call_UpdateStreamingDistribution20170325_402656817(
    name: "updateStreamingDistribution20170325", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20170325_402656818,
    base: "/", makeUrl: url_UpdateStreamingDistribution20170325_402656819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20170325_402656803 = ref object of OpenApiRestCall_402656044
proc url_GetStreamingDistributionConfig20170325_402656805(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20170325_402656804(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a streaming distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656806 = path.getOrDefault("Id")
  valid_402656806 = validateParameter(valid_402656806, JString, required = true,
                                      default = nil)
  if valid_402656806 != nil:
    section.add "Id", valid_402656806
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656807 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Security-Token", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Signature")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Signature", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Algorithm", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Date")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Date", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Credential")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Credential", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656814: Call_GetStreamingDistributionConfig20170325_402656803;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a streaming distribution. 
                                                                                         ## 
  let valid = call_402656814.validator(path, query, header, formData, body, _)
  let scheme = call_402656814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656814.makeUrl(scheme.get, call_402656814.host, call_402656814.base,
                                   call_402656814.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656814, uri, valid, _)

proc call*(call_402656815: Call_GetStreamingDistributionConfig20170325_402656803;
           Id: string): Recallable =
  ## getStreamingDistributionConfig20170325
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string 
                                                                       ## (required)
                                                                       ##     
                                                                       ## : 
                                                                       ## The 
                                                                       ## streaming 
                                                                       ## distribution's 
                                                                       ## ID.
  var path_402656816 = newJObject()
  add(path_402656816, "Id", newJString(Id))
  result = call_402656815.call(path_402656816, nil, nil, nil, nil)

var getStreamingDistributionConfig20170325* = Call_GetStreamingDistributionConfig20170325_402656803(
    name: "getStreamingDistributionConfig20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20170325_402656804,
    base: "/", makeUrl: url_GetStreamingDistributionConfig20170325_402656805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20170325_402656834 = ref object of OpenApiRestCall_402656044
proc url_ListDistributionsByWebACLId20170325_402656836(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2017-03-25/distributionsByWebACLId/"),
                 (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20170325_402656835(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
                                 ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `WebACLId` field"
  var valid_402656837 = path.getOrDefault("WebACLId")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true,
                                      default = nil)
  if valid_402656837 != nil:
    section.add "WebACLId", valid_402656837
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## distributions 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## CloudFront 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## default 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## values 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## both 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## 100.
  section = newJObject()
  var valid_402656838 = query.getOrDefault("Marker")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "Marker", valid_402656838
  var valid_402656839 = query.getOrDefault("MaxItems")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "MaxItems", valid_402656839
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656840 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Security-Token", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Signature")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Signature", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Algorithm", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Date")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Date", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Credential")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Credential", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656847: Call_ListDistributionsByWebACLId20170325_402656834;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
                                                                                         ## 
  let valid = call_402656847.validator(path, query, header, formData, body, _)
  let scheme = call_402656847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656847.makeUrl(scheme.get, call_402656847.host, call_402656847.base,
                                   call_402656847.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656847, uri, valid, _)

proc call*(call_402656848: Call_ListDistributionsByWebACLId20170325_402656834;
           WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20170325
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   
                                                                                  ## Marker: string
                                                                                  ##         
                                                                                  ## : 
                                                                                  ## Use 
                                                                                  ## <code>Marker</code> 
                                                                                  ## and 
                                                                                  ## <code>MaxItems</code> 
                                                                                  ## to 
                                                                                  ## control 
                                                                                  ## pagination 
                                                                                  ## of 
                                                                                  ## results. 
                                                                                  ## If 
                                                                                  ## you 
                                                                                  ## have 
                                                                                  ## more 
                                                                                  ## than 
                                                                                  ## <code>MaxItems</code> 
                                                                                  ## distributions 
                                                                                  ## that 
                                                                                  ## satisfy 
                                                                                  ## the 
                                                                                  ## request, 
                                                                                  ## the 
                                                                                  ## response 
                                                                                  ## includes 
                                                                                  ## a 
                                                                                  ## <code>NextMarker</code> 
                                                                                  ## element. 
                                                                                  ## To 
                                                                                  ## get 
                                                                                  ## the 
                                                                                  ## next 
                                                                                  ## page 
                                                                                  ## of 
                                                                                  ## results, 
                                                                                  ## submit 
                                                                                  ## another 
                                                                                  ## request. 
                                                                                  ## For 
                                                                                  ## the 
                                                                                  ## value 
                                                                                  ## of 
                                                                                  ## <code>Marker</code>, 
                                                                                  ## specify 
                                                                                  ## the 
                                                                                  ## value 
                                                                                  ## of 
                                                                                  ## <code>NextMarker</code> 
                                                                                  ## from 
                                                                                  ## the 
                                                                                  ## last 
                                                                                  ## response. 
                                                                                  ## (For 
                                                                                  ## the 
                                                                                  ## first 
                                                                                  ## request, 
                                                                                  ## omit 
                                                                                  ## <code>Marker</code>.) 
  ##   
                                                                                                           ## WebACLId: string (required)
                                                                                                           ##           
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## ID 
                                                                                                           ## of 
                                                                                                           ## the 
                                                                                                           ## AWS 
                                                                                                           ## WAF 
                                                                                                           ## web 
                                                                                                           ## ACL 
                                                                                                           ## that 
                                                                                                           ## you 
                                                                                                           ## want 
                                                                                                           ## to 
                                                                                                           ## list 
                                                                                                           ## the 
                                                                                                           ## associated 
                                                                                                           ## distributions. 
                                                                                                           ## If 
                                                                                                           ## you 
                                                                                                           ## specify 
                                                                                                           ## "null" 
                                                                                                           ## for 
                                                                                                           ## the 
                                                                                                           ## ID, 
                                                                                                           ## the 
                                                                                                           ## request 
                                                                                                           ## returns 
                                                                                                           ## a 
                                                                                                           ## list 
                                                                                                           ## of 
                                                                                                           ## the 
                                                                                                           ## distributions 
                                                                                                           ## that 
                                                                                                           ## aren't 
                                                                                                           ## associated 
                                                                                                           ## with 
                                                                                                           ## a 
                                                                                                           ## web 
                                                                                                           ## ACL. 
  ##   
                                                                                                                   ## MaxItems: string
                                                                                                                   ##           
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## maximum 
                                                                                                                   ## number 
                                                                                                                   ## of 
                                                                                                                   ## distributions 
                                                                                                                   ## that 
                                                                                                                   ## you 
                                                                                                                   ## want 
                                                                                                                   ## CloudFront 
                                                                                                                   ## to 
                                                                                                                   ## return 
                                                                                                                   ## in 
                                                                                                                   ## the 
                                                                                                                   ## response 
                                                                                                                   ## body. 
                                                                                                                   ## The 
                                                                                                                   ## maximum 
                                                                                                                   ## and 
                                                                                                                   ## default 
                                                                                                                   ## values 
                                                                                                                   ## are 
                                                                                                                   ## both 
                                                                                                                   ## 100.
  var path_402656849 = newJObject()
  var query_402656850 = newJObject()
  add(query_402656850, "Marker", newJString(Marker))
  add(path_402656849, "WebACLId", newJString(WebACLId))
  add(query_402656850, "MaxItems", newJString(MaxItems))
  result = call_402656848.call(path_402656849, query_402656850, nil, nil, nil)

var listDistributionsByWebACLId20170325* = Call_ListDistributionsByWebACLId20170325_402656834(
    name: "listDistributionsByWebACLId20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20170325_402656835,
    base: "/", makeUrl: url_ListDistributionsByWebACLId20170325_402656836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20170325_402656851 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource20170325_402656853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource20170325_402656852(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List tags for a CloudFront resource.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
                                  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Resource` field"
  var valid_402656854 = query.getOrDefault("Resource")
  valid_402656854 = validateParameter(valid_402656854, JString, required = true,
                                      default = nil)
  if valid_402656854 != nil:
    section.add "Resource", valid_402656854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656855 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Security-Token", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Signature")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Signature", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Algorithm", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Date")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Date", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Credential")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Credential", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656862: Call_ListTagsForResource20170325_402656851;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List tags for a CloudFront resource.
                                                                                         ## 
  let valid = call_402656862.validator(path, query, header, formData, body, _)
  let scheme = call_402656862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656862.makeUrl(scheme.get, call_402656862.host, call_402656862.base,
                                   call_402656862.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656862, uri, valid, _)

proc call*(call_402656863: Call_ListTagsForResource20170325_402656851;
           Resource: string): Recallable =
  ## listTagsForResource20170325
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
                                         ##           :  An ARN of a CloudFront resource.
  var query_402656864 = newJObject()
  add(query_402656864, "Resource", newJString(Resource))
  result = call_402656863.call(nil, query_402656864, nil, nil, nil)

var listTagsForResource20170325* = Call_ListTagsForResource20170325_402656851(
    name: "listTagsForResource20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/tagging#Resource",
    validator: validate_ListTagsForResource20170325_402656852, base: "/",
    makeUrl: url_ListTagsForResource20170325_402656853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20170325_402656865 = ref object of OpenApiRestCall_402656044
proc url_TagResource20170325_402656867(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource20170325_402656866(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add tags to a CloudFront resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
                                  ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                  ## Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Resource` field"
  var valid_402656868 = query.getOrDefault("Resource")
  valid_402656868 = validateParameter(valid_402656868, JString, required = true,
                                      default = nil)
  if valid_402656868 != nil:
    section.add "Resource", valid_402656868
  var valid_402656881 = query.getOrDefault("Operation")
  valid_402656881 = validateParameter(valid_402656881, JString, required = true,
                                      default = newJString("Tag"))
  if valid_402656881 != nil:
    section.add "Operation", valid_402656881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656882 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Security-Token", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Signature")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Signature", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Algorithm", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Date")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Date", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Credential")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Credential", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656890: Call_TagResource20170325_402656865;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Add tags to a CloudFront resource.
                                                                                         ## 
  let valid = call_402656890.validator(path, query, header, formData, body, _)
  let scheme = call_402656890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656890.makeUrl(scheme.get, call_402656890.host, call_402656890.base,
                                   call_402656890.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656890, uri, valid, _)

proc call*(call_402656891: Call_TagResource20170325_402656865; Resource: string;
           body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20170325
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
                                       ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                       ## body: JObject (required)
  ##   
                                                                                                                  ## Operation: string (required)
  var query_402656892 = newJObject()
  var body_402656893 = newJObject()
  add(query_402656892, "Resource", newJString(Resource))
  if body != nil:
    body_402656893 = body
  add(query_402656892, "Operation", newJString(Operation))
  result = call_402656891.call(nil, query_402656892, nil, nil, body_402656893)

var tagResource20170325* = Call_TagResource20170325_402656865(
    name: "tagResource20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20170325_402656866, base: "/",
    makeUrl: url_TagResource20170325_402656867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20170325_402656894 = ref object of OpenApiRestCall_402656044
proc url_UntagResource20170325_402656896(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource20170325_402656895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Remove tags from a CloudFront resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
                                  ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                  ## Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Resource` field"
  var valid_402656897 = query.getOrDefault("Resource")
  valid_402656897 = validateParameter(valid_402656897, JString, required = true,
                                      default = nil)
  if valid_402656897 != nil:
    section.add "Resource", valid_402656897
  var valid_402656898 = query.getOrDefault("Operation")
  valid_402656898 = validateParameter(valid_402656898, JString, required = true,
                                      default = newJString("Untag"))
  if valid_402656898 != nil:
    section.add "Operation", valid_402656898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656899 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Security-Token", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Signature")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Signature", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Algorithm", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Date")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Date", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Credential")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Credential", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656907: Call_UntagResource20170325_402656894;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove tags from a CloudFront resource.
                                                                                         ## 
  let valid = call_402656907.validator(path, query, header, formData, body, _)
  let scheme = call_402656907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656907.makeUrl(scheme.get, call_402656907.host, call_402656907.base,
                                   call_402656907.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656907, uri, valid, _)

proc call*(call_402656908: Call_UntagResource20170325_402656894;
           Resource: string; body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20170325
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
                                            ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                            ## body: JObject (required)
  ##   
                                                                                                                       ## Operation: string (required)
  var query_402656909 = newJObject()
  var body_402656910 = newJObject()
  add(query_402656909, "Resource", newJString(Resource))
  if body != nil:
    body_402656910 = body
  add(query_402656909, "Operation", newJString(Operation))
  result = call_402656908.call(nil, query_402656909, nil, nil, body_402656910)

var untagResource20170325* = Call_UntagResource20170325_402656894(
    name: "untagResource20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20170325_402656895, base: "/",
    makeUrl: url_UntagResource20170325_402656896,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}